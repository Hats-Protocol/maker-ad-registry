// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Script, console2 } from "forge-std/Script.sol";
import { Hatter } from "../src/Hatter.sol";

contract Deploy is Script {
  Hatter public hatter;
  bytes32 public SALT = keccak256("lets add some salt to this meal");

  // default values
  bool private verbose = true;
  uint256 public REGISTRAR_HAT;
  uint256 public FACILITATOR_HAT;
  address public FACILITATOR;
  address public CHIEF;
  address public EXPIRATION;
  address public GOV;
  address public IOU;
  address public POLLING;

  /// @notice Override default values, if desired
  function prepare(bool _verbose) public {
    verbose = _verbose;
  }

  function run() public {
    uint256 privKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privKey);
    vm.startBroadcast(deployer);

    hatter = new Hatter{ salt: SALT}(
      REGISTRAR_HAT,
      FACILITATOR_HAT,
      FACILITATOR,
      CHIEF,
      EXPIRATION,
      GOV,
      IOU,
      POLLING);

    vm.stopBroadcast();

    if (verbose) {
      console2.log("Hatter:", address(hatter));
    }
  }
}

// forge script script/Deploy.s.sol -f ethereum --broadcast --verify
