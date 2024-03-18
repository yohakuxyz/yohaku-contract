import { ethers, network, run } from "hardhat";

const dev2: string = "0x06aa005386f53ba7b980c61e0d067cabc7602a62";
const imageURL: string = "QmYRmop52xSAmUC5J5squPrkyu6HtGwQc6yqQNze5q5S8v";

async function main() {
  const SkyBlueFactory = await ethers.getContractFactory("SkyBlue");
  const skyblue = await SkyBlueFactory.deploy(dev2, imageURL);

  await skyblue.waitForDeployment();
  console.log(`SkyBlue deployed to ${skyblue.target} on ${network.name}`);

  await verifyContract(skyblue.target, [dev2, imageURL]);
}

async function verifyContract(address: string, args: any[]) {
  console.log(`Verifying Contract on Etherscan...`);
  await run(`verify:verify`, {
    address: address,
    constructorArguments: args,
  });
  console.log(`Contract verified on Etherscan`);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
// npx hardhat run scripts/deploy.ts --network polygonMumbai
