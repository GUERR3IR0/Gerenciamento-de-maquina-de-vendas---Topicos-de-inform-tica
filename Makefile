GHC = ghc
SRC = src
TARGET = mbt-haskell

.PHONY: build run clean check

build:
	$(GHC) -isrc -Wall $(SRC)/Main.hs -o $(TARGET)

run: build
	./$(TARGET)

check:
	$(GHC) -isrc -Wall -fno-code $(SRC)/Types.hs $(SRC)/FSM.hs

clean:
	rm -f $(TARGET) $(SRC)/*.hi $(SRC)/*.o
