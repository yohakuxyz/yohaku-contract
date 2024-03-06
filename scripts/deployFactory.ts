import { ethers, network, run } from "hardhat";

async function main() {
  const NFTFactory = await ethers.getContractFactory("NFTFactory");
  const factory = await NFTFactory.deploy();
  await factory.waitForDeployment();

  await factory.waitForDeployment();
  console.log(`NFTFactory deployed to ${factory.target} on ${network.name}`);

  await verifyContract(factory.target);
}

async function verifyContract(address: string) {
  console.log(`Verifying Contract on Etherscan...`);
  await run(`verify:verify`, {
    address: address,
  });
  console.log(`Contract verified on Etherscan`);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
// npx hardhat run scripts/deploy.ts --network polygonMumbai 0x772dD39407A804dA53744d3fAB8445bC09d54295 0x06aa005386f53ba7b980c61e0d067cabc7602a62 ipfs://bafkreidp6xswfzex5mr6akr7azn3e4rza57ukuxyo2tq6slymliaeuenoi
