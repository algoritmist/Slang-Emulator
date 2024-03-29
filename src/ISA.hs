{-# OPTIONS_GHC -Wno-missing-export-lists #-}
module ISA where
import           Data.List (find)

type Name = String

wordSize :: Int
wordSize = 8

shft :: Int
shft = 3

maxOffset :: Int
maxOffset = 4100

data Register =
    Register
    {
        rType :: RegisterType,
        name  :: Name
    }
    deriving(Ord, Eq)

data RegisterType =
    Temporary |
    Argument  |
    Saved     |
    Virtual   |
    Hardwired |
    Special
    deriving(Ord, Eq)


instance Show Register where
    show = name

zero :: Register
zero = Register Hardwired "zero"
ra :: Register
ra = Register Special "ra"
rin :: Register
rin = Register Special "rin"
dr :: Register
dr = Register Special "dr"
pc :: Register
pc = Register Special "pc"
sp :: Register
sp = Register Special "sp"
a0 :: Register
a0 = Register Argument "a0"
a1 :: Register
a1 = Register Argument "a1"
a2 :: Register
a2 = Register Argument "a2"
s0 :: Register
s0 = Register Saved "s0"
s1 :: Register
s1 = Register Saved "s1"
s2 :: Register
s2 = Register Saved "s2"
t0 :: Register
t0 = Register Temporary "t0"
t1 :: Register
t1 = Register Temporary "t1"
t2 :: Register
t2 = Register Temporary "t2"
t3 :: Register
t3 = Register Temporary "t3"
rout :: Register
rout = Register Special "rout"
tr :: Register
tr = Register Special "tr"

registers :: [Register]
registers = [zero, ra, pc, sp, dr, rin, a0, a1, a2, s0, s1, s2, t0, t1, t2, t3, rout, tr]

gpRegs :: [Register]
gpRegs = [zero, ra, sp, dr, a0, a1, a2, s0, s1, s2, t0, t1, t2, t3, tr]

argumentRegisters :: [Register]
argumentRegisters = filter (\r -> rType r == Argument) gpRegs

temporaryRegisters :: [Register]
temporaryRegisters = filter (\r -> rType r == Temporary) gpRegs

savedRegisters :: [Register]
savedRegisters = filter (\r -> rType r == Saved) gpRegs


toReg :: String -> Register
toReg s = case find (\r -> name r == s) registers of
    Just reg -> reg
    _        -> error "Register does not exist"


type Opcode = Int
type Rd = Register
type Rs1 = Register
type Rs2 = Register
type Imm = Int
type LabelName = String

data Instruction =
    MathOp Opcode Rd Rs1 Rs2 Imm |
    Branch    Opcode Rs1 Rs2 Imm |
    RegisterMemory Opcode Rd Rs1 Imm |
    MemoryMemory Opcode Rs1 Imm |
    MathImmideate Opcode Rd Rs1 Imm |
    Jump Opcode Rd Imm |
    Ret |
    Nop |
    Halt |
    SavePC |
    Label Name |
    PseudoBranch Opcode Rs1 Rs2 LabelName |
    PseudoJump Opcode LabelName |
    PseudoCall Rd Imm |
    PseudoLabelCall LabelName
    deriving(Eq)

instance Show Instruction where
    show(MathOp op rd rs1 rs2 _) =
        let
            prefix = case op of
                0 -> "add"
                1 -> "sub"
                2 -> "mul"
                3 -> "div"
                8 -> "mod"
                _ -> error $ "Error: unknown MathOp with op = " ++ show op
        in
            prefix ++ " " ++ show rd ++ " " ++ show rs1 ++ " " ++ show rs2
    show(Branch op rs1 rs2 imm) =
        let
            prefix = case op of
                4 -> "be"
                5 -> "bne"
                6 -> "bg"
                7 -> "bl"
                _ -> error $ "Error: unknown Branch with op = " ++ show op
        in
            prefix ++ " "  ++ show rs1 ++ " " ++ show rs2 ++ " " ++ show imm
    show(MathImmideate op rd rs1 imm) =
        let
            prefix = case op of
                16 -> "addI"
                17 -> "subI"
                18 -> "mulI"
                19 -> "divI"
                24 -> "modI"
                _ -> error $ "Error: unknown MathImmediate with op = " ++ show op
        in
            prefix ++ " " ++ show rd ++ " " ++ show rs1 ++ " " ++ show imm
    show(RegisterMemory op rd rs1 imm) =
        let
            prefix = case op of
                20 -> "lwm"
                21 -> "swm"
                _ -> error $ "Error: unknown RegisterMemory with op = " ++ show op
        in
            prefix ++ " " ++ show rd ++ " " ++ show rs1 ++ " " ++ show imm

    show(MemoryMemory op rs1 imm) =
        let
            prefix = case op of
                22 -> "lwi"
                23 -> "swo"
                _ -> error $ "Error: unknown MemoryMemory with op = " ++ show op
        in
            prefix ++ " " ++ show rs1 ++ " " ++ show imm
    show (Jump _ rd imm) = "jump " ++ show rd ++ " " ++ show imm
    show Nop = "nop"
    show Halt = "halt"
    show (Label name) = name ++ ":"
    show (PseudoBranch op rs1 rs2 label) =
        let
            prefix = case op of
                4 -> "bel"
                5 -> "bnel"
                6 -> "bgl"
                7 -> "bll"
        in
            prefix ++ " "  ++ show rs1 ++ " " ++ show rs2 ++ " " ++ label
    show (PseudoJump _ label) = "jumpl " ++ label
    show (PseudoCall rd imm) = "call " ++ show rd ++ " " ++ show imm
    show (PseudoLabelCall label) = "call " ++ label
    show Ret = "ret"
    show SavePC = "savePC"

-- R-R instructions
add :: Rd -> Rs1 -> Rs2 -> Instruction
add rd rs1 rs2 = MathOp 0 rd rs1 rs2 0
sub :: Rd -> Rs1 -> Rs2 -> Instruction
sub rd rs1 rs2 = MathOp 1 rd rs1 rs2 0
mul :: Rd -> Rs1 -> Rs2 -> Instruction
mul rd rs1 rs2 = MathOp 2 rd rs1 rs2 0
div :: Rd -> Rs1 -> Rs2 -> Instruction
div rd rs1 rs2 = MathOp 3 rd rs1 rs2 0
mod :: Rd -> Rs1 -> Rs2 -> Instruction
mod rd rs1 rs2 = MathOp 8 rd rs1 rs2 0
-- Branch instructions
be :: Rs1 -> Rs2 -> Imm -> Instruction
be = Branch 4 -- if(@rs1 == @rs2) pc <- pc + imm
bne :: Rs1 -> Rs2 -> Imm -> Instruction
bne = Branch 5
bg :: Rs1 -> Rs2 -> Imm -> Instruction
bg = Branch 6
bl :: Rs1 -> Rs2 -> Imm -> Instruction
bl = Branch 7
jmp :: Rd -> Imm -> Instruction
jmp = Jump 31

-- R-I instructions
addI :: Rd -> Rs1 -> Imm -> Instruction
addI = MathImmideate 16
subI :: Rd -> Rs1 -> Imm -> Instruction
subI = MathImmideate 17
mulI :: Rd -> Rs1 -> Imm -> Instruction
mulI = MathImmideate 18
divI :: Rd -> Rs1 -> Imm -> Instruction
divI = MathImmideate 19
modI :: Rd -> Rs1 -> Imm -> Instruction
modI = MathImmideate 24

-- R-M instructions
lwm :: Rd -> Rs1 -> Imm -> Instruction
lwm = RegisterMemory 20
swm :: Rd -> Rs1 -> Imm -> Instruction
swm = RegisterMemory 21

-- M-M instructions
lwi :: Rs1 -> Imm -> Instruction
lwi = MemoryMemory 22
swo :: Rs1 -> Imm -> Instruction
swo = MemoryMemory 23

-- Pseudo instructions
push :: Register -> [Instruction]
push rs = [swm rs sp 0, subI sp sp 1]
pop :: Register -> [Instruction]
pop rd = [addI sp sp 1, lwm rd sp 0]

type Offset = Int
call :: Register -> Offset -> [Instruction]
call rd imm =  push ra ++ [SavePC, jmp rd imm] ++ pop ra

-- Pseudo branch instructions
bel :: Rs1 -> Rs2 -> LabelName -> Instruction
bel = PseudoBranch 4
bnel :: Rs1 -> Rs2 -> LabelName -> Instruction
bnel = PseudoBranch 5
bgl :: Rs1 -> Rs2 -> LabelName -> Instruction
bgl = PseudoBranch 6
bll :: Rs1 -> Rs2 -> LabelName -> Instruction
bll = PseudoBranch 7
jmpl :: LabelName -> Instruction
jmpl = PseudoJump 31
