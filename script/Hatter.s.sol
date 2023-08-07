// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Script, console2 } from "forge-std/Script.sol";
// import { Hatter } from "../src/Hatter.sol";

contract Deploy is Script {
  address public hatter;
  bytes32 public SALT = keccak256("lets add some salt to this meal");

  // default values
  bool private verbose = true;
  uint256 internal FACILITATOR_HAT =
    1_779_356_891_414_358_658_484_920_215_249_427_053_220_885_443_987_746_547_592_268_148_113_408; // goerli 66.1.1
  address internal FACILITATOR = 0xA7a5A2745f10D5C23d75a6fd228A408cEDe1CAE5; // spengrah.eth

  /// @notice Override default values, if desired
  function prepare(bool _verbose, uint256 facilitatorHat, address facilitator) public {
    verbose = _verbose;
    FACILITATOR_HAT = facilitatorHat;
    FACILITATOR = facilitator;
  }

  function run() public {
    uint256 privKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privKey);
    vm.startBroadcast(deployer);

    hatter = deployCode("optimized-out/Hatter.sol/Hatter.json", abi.encode(FACILITATOR_HAT, FACILITATOR));

    vm.stopBroadcast();

    if (verbose) {
      console2.log("Hatter:", address(hatter));
    }
  }
}

// forge script script/Hatter.s.sol -f ethereum --broadcast --verify

/* 
 forge verify-contract --chain-id 5 --num-of-optimizations 1000000 --watch --constructor-args $(cast abi-encode \
 "constructor(uint256,address)" "1779356891414358658484920215249427053220885443987746547592268148113408" \
 "0xA7a5A2745f10D5C23d75a6fd228A408cEDe1CAE5") --compiler-version v0.8.20 0xF8e5fE6E1b355E883dC6Ad5362b823e1e350B511 \
 src/Hatter.sol:Hattter --etherscan-api-key $ETHERSCAN_KEY --show-standard-json-input > etherscan.json
*/
