import axios from 'axios';
import fs from 'fs';
import { ethers } from 'ethers';
import * as dotenv from 'dotenv';

dotenv.config();

async function simulateTransaction() {
    const jsonData = fs.readFileSync('./data/scanApiResponse.json', 'utf8');
    const parsedData = JSON.parse(jsonData);

    const srcEid = parsedData.data[0].pathway.srcEid;
    const senderAddress = parsedData.data[0].pathway.sender.address;
    const nonce = parsedData.data[0].pathway.nonce;
    const receiverAddress = parsedData.data[0].pathway.receiver.address;
    const guid = parsedData.data[0].guid;
    const payload = parsedData.data[0].source.tx.payload;

    // Correcting the origin object to match the expected ABI encoding
    const origin = [
        srcEid,
        ethers.utils.hexZeroPad(senderAddress, 32),
        nonce
    ];

    const extraData = "0x";

    // ABI encoding for the lzReceive function call
    const iface = new ethers.utils.Interface([
        "function lzReceive((uint32,bytes32,uint64),address,bytes32,bytes,bytes)"
    ]);

    const inputData = iface.encodeFunctionData("lzReceive", [origin, receiverAddress, guid, payload, extraData]);

    const { TENDERLY_ACCOUNT_SLUG, TENDERLY_PROJECT_SLUG, TENDERLY_ACCESS_KEY } = process.env;

    const url = `https://api.tenderly.co/api/v1/account/${TENDERLY_ACCOUNT_SLUG}/project/${TENDERLY_PROJECT_SLUG}/simulate`;

    console.log(url);

    try {
        const simulation = await axios.post(
            url,
            {
                network_id: '1',
                block_number: 16533883, // Example block number, adjust as needed
                from: senderAddress,
                to: receiverAddress,
                gas: 8000000, // Example gas limit, adjust as needed
                gas_price: 0, // Example gas price, adjust as needed
                value: 0, // Example value, adjust as needed
                input: inputData,
                simulation_type: 'quick',
            },
            {
                headers: {
                    'X-Access-Key': TENDERLY_ACCESS_KEY as string,
                },
            }
        );

        console.log(simulation.data);
    } catch (error) {
        console.log(error.response.data);
        // if (error.response && error.response.status === 401) {
        //     console.error('Error 401: Unauthorized -', error.response.data);
        // } else {
        //     console.error('Error simulating transaction:', error);
        // }
    }
}

simulateTransaction();
