{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Exit
import System.IO
import System.Environment
import System.Console.GetOpt
import Simple.Commands

--------------------------------------------------------------------------------
-- | Flags with their corresponding description
flags :: [OptDescr Flag]
flags = [ Option ['d'] ["due-by"]              (ReqArg DueBy "DATE")
               "Get todos due by a certain date"
        , Option ['l'] ["late"]                (NoArg Late)
                "Get todos that are late"
        , Option ['w'] ["with-hashtags"]       (NoArg WithHashtags)
                "Get todos with the associated hashtags"
        , Option ['h'] ["hashtags"]            (ReqArg SearchHashtag "HASHTAGS")
                "Get todos for a certain hashtag"
        , Option ['o'] ["order-by-priority"] (NoArg OrderByPriority)
                "Get todos ordered by priority"
        , Option ['p'] ["priority"]            (ReqArg SetPriority "PRIORITY")
                "When adding a todo, you can set its priority"
        , Option ['h'] ["help"]                (NoArg Help)
                "Show help menu"
        , Option ['v'] ["version"]             (NoArg Version)
                "Show version"
        ]

--------------------------------------------------------------------------------
-- | Parse the command and the corresponding flags (if any)
parse :: [String] -> Either String (Command, [Flag])
-- Simple parsing of commands
parse []                = Left "Wrong number of arguments."
parse ("--help":_)      = Left "This is help"
parse ("--version":_)   = Left "Version: 0.1.0.0"
parse args = case args of
               ("find":x:argv)  -> makeCommand (Find (read x :: Int)) argv
               ("add":x:argv)   -> makeCommand (Add (read x :: String)) argv
               ("complete":x:_) -> makeCommand (Complete (read x :: Int)) []
               ("list":argv)    -> makeCommand List argv
               _                -> Left "Unrecognized command."

makeCommand :: Command -> [String] -> Either String (Command, [Flag])
makeCommand c argv = case getOpt Permute flags argv of
                       (args', _, []) -> Right(c, args')
                       (_, _, errs)   -> Left (concat errs)

--------------------------------------------------------------------------------
-- | Gets the results of a command and its corresponding flags
getResults :: Either String (Command, [Flag]) -> IO ()
-- An error happened
getResults (Left s) = hPutStrLn stderr s
                   >> hPutStrLn stderr "Run with --help for help."
                   >> exitWith (ExitFailure 1)
-- We have an appropriate command and its results
getResults (Right (c, flags')) = runAndPrintCommand c flags'
                              >> exitWith ExitSuccess

main :: IO ()
main = do
    parsed <- getArgs >>= return . parse
    getResults parsed
