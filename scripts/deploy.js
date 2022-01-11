const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
    const gameContract = await gameContractFactory.deploy(
        ["Harmony", "Ron", "Harry"],       // Names
        ["QmNWEty1QaptJX3mTUaWmqgCk338wHHHzfqk1BpXzV1Fid", // Images
            "QmZGct9kVbA5Dpor3tJF4jpzq2Q7PL8hmnCppdFskijHJ7",
            "QmNtbNMsXYQZBG57wBJn8okfDEpLv42zrs81nyVQ3cbE9C"],
        [500, 500, 800],                    // HP values
        [50, 50, 100],                       // Attack damage values
        'Voldemort',
        'Qmessp5sSrnMoEMnRD2MffwxF9f1pX9PM23DuNYkQn38Tk',
        2000, // boss hp
        120 // boss damage
    );
    await gameContract.deployed();
    console.log("Contract deployed to:", gameContract.address);

    txn = await gameContract.mintCharacterNFT(2);
    await txn.wait();
    console.log("Character minted!");

    for (let i = 0; i < 7; i++) {
        txn = await gameContract.attackBoss();
        await txn.wait();
      }


};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();