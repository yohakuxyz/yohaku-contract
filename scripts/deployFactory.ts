import { ethers, network, run } from "hardhat";

const dev2: string = "0x06aa005386f53ba7b980c61e0d067cabc7602a62";
const eas = "0x5E634ef5355f45A855d02D66eCD687b1502AF790"; //polygon pos
const registry = "0x7876EEF51A891E737AF8ba5A5E0f0Fd29073D5a7";// polygon pos

async function main() {
  const NFTFactory = await ethers.getContractFactory("NFTFactory");
  const factory = await NFTFactory.deploy(dev2, eas, registry);
  await factory.waitForDeployment();

  await factory.waitForDeployment();
  console.log(`NFTFactory deployed to ${factory.target} on ${network.name}`);

  await verifyContract(factory.target, [dev2, eas, registry]);
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
// npx hardhat run scripts/deploy.ts --network polygonMumbai 0x772dD39407A804dA53744d3fAB8445bC09d54295 0x06aa005386f53ba7b980c61e0d067cabc7602a62 ipfs://bafkreidp6xswfzex5mr6akr7azn3e4rza57ukuxyo2tq6slymliaeuenoi
