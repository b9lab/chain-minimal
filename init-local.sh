#!/bin/sh

# Run first
# docker run -t -i --name da-layer -p 26650:26650 -p 26657:26657 -p 26658:26658 -p 26659:26659 -p 9090:9090 ghcr.io/rollkit/local-celestia-devnet:v0.12.7
# Or
# docker run -t -i --name da-layer -p 26650:26650 -p 26657:26657 -p 26658:26658 -p 26659:26659 -p 9090:9090 celestia-da

# set variables for the chain
VALIDATOR_NAME=validator1
CHAIN_ID=mini
KEY_NAME=mini-key
KEY_2_NAME=mini-key-2
KEY_RELAY=mini-relay
CHAINFLAG="--chain-id ${CHAIN_ID}"
TOKEN_AMOUNT="10000000000000000000000000stake"
STAKING_AMOUNT="1000000000stake"

# query the DA Layer start height, in this case we are querying
# our local devnet at port 26657, the RPC. The RPC endpoint is
# to allow users to interact with Celestia's nodes by querying
# the node's state and broadcasting transactions on the Celestia
# network. The default port is 26657.
DA_BLOCK_HEIGHT=$(curl http://0.0.0.0:26657/block | jq -r '.result.block.header.height')

# rollkit logo
cat <<'EOF'

                 :=+++=.                
              -++-    .-++:             
          .=+=.           :++-.         
       -++-                  .=+=: .    
   .=+=:                        -%@@@*  
  +%-                       .=#@@@@@@*  
    -++-                 -*%@@@@@@%+:   
       .=*=.         .=#@@@@@@@%=.      
      -++-.-++:    =*#@@@@@%+:.-++-=-   
  .=+=.       :=+=.-: @@#=.   .-*@@@@%  
  =*=:           .-==+-    :+#@@@@@@%-  
     :++-               -*@@@@@@@#=:    
        =%+=.       .=#@@@@@@@#%:       
     -++:   -++-   *+=@@@@%+:   =#*##-  
  =*=.         :=+=---@*=.   .=*@@@@@%  
  .-+=:            :-:    :+%@@@@@@%+.  
      :=+-             -*@@@@@@@#=.     
         .=+=:     .=#@@@@@@%*-         
             -++-  *=.@@@#+:            
                .====+*-.  

   ______         _  _  _     _  _   
   | ___ \       | || || |   (_)| |  
   | |_/ /  ___  | || || | __ _ | |_ 
   |    /  / _ \ | || || |/ /| || __|
   | |\ \ | (_) || || ||   < | || |_ 
   \_| \_| \___/ |_||_||_|\_\|_| \__|
EOF

# echo variables for the chain
echo -e "\n Your DA_BLOCK_HEIGHT is $DA_BLOCK_HEIGHT \n"

# build the mini chain with Rollkit
# ignite chain build

# reset any existing genesis/chain data
minid tendermint unsafe-reset-all

# initialize the validator with the chain ID you set
minid init $VALIDATOR_NAME --chain-id $CHAIN_ID

# add keys for key 1 and key 2 to keyring-backend test
minid keys add $KEY_NAME --keyring-backend test
minid keys add $KEY_2_NAME --keyring-backend test
echo "milk verify alley price trust come maple will suit hood clay exotic" | minid keys add $KEY_RELAY --keyring-backend test  --recover

# add these as genesis accounts
minid genesis add-genesis-account $KEY_NAME $TOKEN_AMOUNT --keyring-backend test
minid genesis add-genesis-account $KEY_2_NAME $TOKEN_AMOUNT --keyring-backend test
minid genesis add-genesis-account $KEY_RELAY $TOKEN_AMOUNT --keyring-backend test

# set the staking amounts in the genesis transaction
minid genesis gentx $KEY_NAME $STAKING_AMOUNT --chain-id $CHAIN_ID --keyring-backend test

# collect genesis transactions
minid genesis collect-gentxs

# copy centralized sequencer address into genesis.json
# Note: validator and sequencer are used interchangeably here
ADDRESS=$(jq -r '.address' ~/.minid/config/priv_validator_key.json)
PUB_KEY=$(jq -r '.pub_key' ~/.minid/config/priv_validator_key.json)
jq --argjson pubKey "$PUB_KEY" '.consensus["validators"]=[{"address": "'$ADDRESS'", "pub_key": $pubKey, "power": "1000", "name": "Rollkit Sequencer"}]' ~/.minid/config/genesis.json > temp.json && mv temp.json ~/.minid/config/genesis.json

# create a restart-local.sh file to restart the chain later
[ -f restart-local.sh ] && rm restart-local.sh
echo "DA_BLOCK_HEIGHT=$DA_BLOCK_HEIGHT" >> restart-local.sh

echo "minid start --rollkit.aggregator --rollkit.da_address=\"http://localhost:26650\" --rollkit.da_start_height \$DA_BLOCK_HEIGHT --rpc.laddr tcp://127.0.0.1:36657 --grpc.address 127.0.0.1:9290 --p2p.laddr \"0.0.0.0:36656\" --minimum-gas-prices="0.025stake"" >> restart-local.sh
chmod a+x restart-local.sh

# start the chain
minid start --rollkit.aggregator --rollkit.da_address="http://localhost:26650" --rollkit.da_start_height $DA_BLOCK_HEIGHT --rpc.laddr tcp://127.0.0.1:36657 --grpc.address 127.0.0.1:9290 --p2p.laddr "0.0.0.0:36656" --minimum-gas-prices="0.025stake"
