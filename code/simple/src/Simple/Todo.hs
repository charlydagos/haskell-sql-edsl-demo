{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Simple.Todo
    ( -- * Exports
      Todo (..)
    , isNew
    , allTodos
    , findTodo
    , deleteTodo
    , addTodo
    , allTodosByDate
    , allTodosByPrio
    , allLateTodos
    ) where

import GHC.Int                            (Int64)
import Database.PostgreSQL.Simple
import Database.PostgreSQL.Simple.FromRow (fromRow, field)
import Database.PostgreSQL.Simple.ToRow   (toRow)
import Database.PostgreSQL.Simple.ToField (toField)
import Database.PostgreSQL.Simple.Time    (Date)
import Database.PostgreSQL.Simple.SqlQQ   (sql)

data Todo = Todo { getId       :: !(Maybe Int) -- Can be null
                 , getTitle    :: !String      -- Title of the todo
                 , getDueDate  :: !Date        -- Date of the todo
                 , getPrio     :: !(Maybe Int) -- Priority of the todo
                 } deriving (Show)

instance FromRow Todo where
    fromRow = Todo <$> field -- id
                   <*> field -- title
                   <*> field -- due date
                   <*> field -- prio

instance ToRow Todo where
    toRow t = [ toField (getTitle t)
              , toField (getDueDate t)
              , toField (getPrio t)
              ]

isNew :: Todo -> Bool
isNew t = Nothing == getId t

allTodos :: Connection -> IO [Todo]
allTodos conn = query_ conn q
                where
                  q = [sql| select id, title, due_date, prio
                            from todos |]

findTodo :: Connection -> Int -> IO Todo
findTodo conn tid =
               return . head =<< query conn q (Only tid)
               where
                 q = [sql| select id, title, due_date, prio
                           from todos
                           where id = ? |]

deleteTodo :: Connection -> Int -> IO Int64
deleteTodo conn tid = execute conn q (Only tid)
                      where
                        q = [sql| delete from todos
                                  where id = ? |]

addTodo :: Connection -> Todo -> IO (Only Int)
addTodo conn t = return . head =<< query conn q t
                 where
                   q = [sql| insert into todos (title, due_date, priority)
                             values (?, ?, ?)
                             returning id |]

allTodosByDate :: Connection -> Date -> IO [Todo]
allTodosByDate conn d = query conn q (Only d)
                        where
                          q = [sql| select id, title, due_date, prio
                                    from todos
                                    where due_date = ? |]

allTodosByPrio :: Connection -> IO [Todo]
allTodosByPrio conn = query_ conn q
                      where
                        q = [sql| select id, title, due_date, prio
                                  from todos
                                  order by prio desc
                                  nulls last |]

allLateTodos :: Connection -> IO [Todo]
allLateTodos conn = query_ conn q
                    where
                      q = [sql| select id, title, due_date, prio
                                from todos
                                where due_date < current_date |]

