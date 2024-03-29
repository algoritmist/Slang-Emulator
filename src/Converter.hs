module Converter(toReal) where
import           Data.Map as Map (Map, empty, insert, lookup)
import           ISA      (wordSize)
import qualified ISA
toReal :: [ISA.Instruction] -> [ISA.Instruction]
toReal xs = toRealHelper xs (buildMap xs) 0 ""

type LabelMap = Map ISA.LabelName Int

buildMap :: [ISA.Instruction] -> LabelMap
buildMap xs = buildMapHelper 0 xs Map.empty ""

buildMapHelper :: Int -> [ISA.Instruction] -> LabelMap -> ISA.LabelName -> LabelMap
buildMapHelper addr (ISA.Label name : xs) mp topLabel =
    let
        name' = case name of
            '_':local -> topLabel ++ '.' : local
            _         -> name
        topLabel' = if head name == '_' then topLabel else name
        mp' = Map.insert name' addr mp
    in
        buildMapHelper (addr + wordSize) xs mp' topLabel'
buildMapHelper addr (ISA.PseudoCall _ _ : xs) mp topLabel = buildMapHelper (addr + 5 * wordSize + wordSize) xs mp topLabel
buildMapHelper addr (ISA.PseudoLabelCall _ : xs) mp topLabel = buildMapHelper (addr + 5 * wordSize + wordSize) xs mp topLabel
buildMapHelper addr (_:xs) mp topLabel = buildMapHelper (addr + wordSize) xs mp topLabel
buildMapHelper _ [] mp _ = mp


toRealHelper :: [ISA.Instruction] -> LabelMap -> Int -> ISA.LabelName -> [ISA.Instruction]

toRealHelper (ISA.Label name : xs) mp addr topLabel =
    ISA.Nop : toRealHelper xs mp (addr + wordSize) (if head name == '_' then topLabel else name)
toRealHelper (ISA.PseudoCall rd imm : xs) mp addr topLabel =
    let
        instructions = ISA.call rd imm
    in
        toRealHelper (instructions ++ xs) mp addr topLabel

toRealHelper (ISA.PseudoLabelCall name : xs) mp addr topLabel =
    let
        name' = case name of
            '_':local -> topLabel ++ '.' : local
            _         -> name
        labelAddr = Map.lookup name' mp
    in
        case labelAddr of
            Nothing -> error $ "No label with name " ++ name'
            Just address ->
                    toRealHelper (ISA.PseudoCall ISA.zero address : xs) mp addr topLabel

toRealHelper (ISA.PseudoJump _ name : xs) mp addr topLabel =
    let
        name' = case name of
            '_':local -> topLabel ++ '.' : local
            _         -> name
        labelAddr = Map.lookup name' mp
    in
        case labelAddr of
            Nothing -> error $ "No label with name " ++ name'
            Just address ->
                ISA.jmp ISA.zero address : toRealHelper xs mp (addr + wordSize) topLabel

toRealHelper (ISA.PseudoBranch opcode rs1 rs2 name : xs) mp addr topLabel =
    let
        name' = case name of
            '_':local -> topLabel ++ '.' : local
            _         -> name
        labelAddr = Map.lookup name' mp
    in
        case labelAddr of
            Nothing -> error $ "No label with name " ++ name'
            Just address ->
                    let
                        diff = address - addr - wordSize
                    in
                        ISA.Branch opcode rs1 rs2 diff : toRealHelper xs mp (addr + wordSize) topLabel

toRealHelper (x:xs) mp addr topLabel = x : toRealHelper xs mp (addr + wordSize) topLabel
toRealHelper [] _ _ _ = []

