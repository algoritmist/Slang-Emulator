module AsmLib(program, convert) where
import qualified Converter
import qualified Parser

program = Parser.program
convert = Converter.toReal
