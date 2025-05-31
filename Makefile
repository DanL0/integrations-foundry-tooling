# Load environment variables from .env file
include .env
export $(shell sed 's/=.*//' .env)

# Needed to make sure the recipe always runs, otherwise it will see the broadcast folder and not run it
.PHONY: simulate broadcast 

simulate:
	forge script script/SimulateReceive.s.sol --rpc-url $(DESTINATION_CHAIN_RPC_URL) --account burner -vvvv

broadcast:
	forge script script/SimulateReceive.s.sol --rpc-url $(DESTINATION_CHAIN_RPC_URL) --account burner --broadcast