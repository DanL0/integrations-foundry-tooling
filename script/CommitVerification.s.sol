// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import { SendParam, OFTReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

import { ILayerZeroEndpointV2, Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
// import { ReceiveUln302 } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/uln302/ReceiveULN302.sol";
import { IReceiveUlnE2 } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/interfaces/IReceiveUlnE2.sol";

contract CommitVerification is Script {
    using stdJson for string;

    function run() public {
        string memory json = vm.readFile("./data/scanApiResponse.json");
        uint32 srcEid = uint32(json.readUint(".data[0].pathway.srcEid"));
        address senderAddress = json.readAddress(".data[0].pathway.sender.address");
        uint64 nonce = uint64(json.readUint(".data[0].pathway.nonce"));
        bytes32 sender = addressToBytes32(senderAddress);
        address receiver = json.readAddress(".data[0].pathway.receiver.address");
        // bytes32 guid = json.readBytes32(".data[0].guid");
        // bytes memory payload = json.readBytes(".data[0].source.tx.payload");
        bytes memory packetHeader = hex"01000000000000000100007595000000000000000000000000153b7616ba77b7e4fafa555434c44e2c9ca4fb910000759600000000000000000000000071cbdf07964c30b447ebe9d9860d77be5d478800";
        bytes32 payloadHash = hex"599e253acb95c4ee84e8c53052121791dd38a554cabf98b30828a760c0d82abe";

        Origin memory origin = Origin({
            srcEid: srcEid,
            sender: sender,
            nonce: nonce
        });
        // bytes memory extraData = "";

        ILayerZeroEndpointV2 endpoint;

        try IOAppCore(receiver).endpoint() returns (ILayerZeroEndpointV2 _endpoint) {
            endpoint = _endpoint;
        } catch {
            console.log("OApp.endpoint() method reverted - SimulateReceive script only supports OApps implementing IOAppCore interface.");
        }

        endpoint = ILayerZeroEndpointV2(address(0x1a44076050125825900e736c501f859c50fE728c));

        bool verifiable = endpoint.verifiable(origin, receiver);

        if (verifiable) {
            (address receiveLibAddress,) = endpoint.getReceiveLibrary(receiver, srcEid);
        
            IReceiveUlnE2 receiveLib = IReceiveUlnE2(receiveLibAddress);
            receiveLib.commitVerification(packetHeader, payloadHash);
        } else {
            console.log("not verifiable");

            uint64 inboundNonce = endpoint.inboundNonce(receiver, origin.srcEid, origin.sender);
            uint64 lazyInboundNonce = endpoint.lazyInboundNonce(receiver, origin.srcEid, origin.sender);
            bytes32 inboundPayloadHash = endpoint.inboundPayloadHash(receiver, origin.srcEid, origin.sender, nonce);

            console.log("inboundNonce", vm.toString(inboundNonce));
            console.log("inboundPayloadHash", vm.toString(inboundPayloadHash));

            if (origin.nonce <= lazyInboundNonce) {
                console.log("origin.nonce must be higher than lazyInboundNonce");
                console.log("origin.nonce", origin.nonce, "lazyInboundNonce", lazyInboundNonce);
            }
        }
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}