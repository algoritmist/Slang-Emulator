module Main(main) where
import           System.Environment.Blank (getArgs)
import           System.FilePath          (replaceExtension)
import           Text.Parsec.Prim         (parse)
import           TranslatorLib

main :: IO ()
main = do
    args <-  getArgs
    if length args /= 1
        then do
            putStrLn "usage: slang-compiler <source_code.sl>"
    else do
        let file = head args
        fileContents <- readFile file
        let result = parse program file fileContents
        case result of
            Left err -> print err
            Right program -> do
                let (instructions, dt) = tranlsate program
                let outBin = replaceExtension file ".asm"
                let outData = replaceExtension file ".dmem"
                writeFile outBin $ concatMap (\x -> show x ++ "\n") instructions
                writeFile outData $ concatMap (\x -> show x ++ "\n") dt


