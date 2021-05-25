const ORMarketLib = artifacts.require('ORMarketLib')

const {
  prepareContracts, createNewMarket,
  executeControllerMethod,
} = require('./utils/market.js')
const { toBN } = web3.utils
var BigNumber = require('bignumber.js')

contract('OR validation rewards', function([, creator, oracle, investor1, trader, investor2]) {

  let collateralToken
  let fixedProductMarketMaker
  let positionIds

  let controller;
  let rewardsProgram;
  
  let oneDayBlocks = 5761;

  before(async function() {
    let retArray = await prepareContracts(creator, oracle, investor1, trader, investor2)
    controller = retArray[0];
    rewardsProgram = retArray[1];
  })

  it('can be created by factory', async function() {
    let retValues = await createNewMarket(creator)
    fixedProductMarketMaker = retValues[0]
    collateralToken = retValues[1]
    positionIds = retValues[2]
  })

  const addedFunds1 = toBN(1e18)
  it('can be funded', async function() {
    await collateralToken.deposit({ value: addedFunds1, from: investor1 })
    await collateralToken.approve(controller.address, addedFunds1, { from: investor1 })
    await controller.marketAddLiquidity(fixedProductMarketMaker.address, addedFunds1, { from: investor1 })

    // All of the amount have been converted...
    expect((await collateralToken.balanceOf(investor1)).toString()).to.equal('0')
    expect((await fixedProductMarketMaker.balanceOf(investor1)).toString()).to.equal(addedFunds1.toString())
  })


  it('Should vote for the approval of this created market', async function() {
    const inv1Attr = [fixedProductMarketMaker.address, true, { from: investor1 }]
    const inv2Attr = [fixedProductMarketMaker.address, false, { from: investor2 }]
    const oracleAttr = [fixedProductMarketMaker.address, false, { from: oracle }]

    await executeControllerMethod('castGovernanceValidatingVote', inv1Attr)
    await executeControllerMethod('castGovernanceValidatingVote', inv2Attr)
    await executeControllerMethod('castGovernanceValidatingVote', oracleAttr)
  })

  it('Should vote for the approval of this created market', async function() {
    let today = new Date();
    // set this as the start of the day.
    today.setHours(0,0,0,0);
    let todayInSeconds = Math.floor(today.getTime() / 1000);
    
    let rewardsDaily = await rewardsProgram.lpRewardPerDay.call();
    
    let rewards = await rewardsProgram.getLPReward(fixedProductMarketMaker.address, investor1);
    let pendingRewards = rewards['pendingRewards'];
    let claimedRewards = rewards['claimedRewards'];
    
    // Information about the first user that added a new liquidity.
    let inv1UserInformation = await rewardsProgram.lpUsers.call(fixedProductMarketMaker.address, investor1);
    let inv1UserTotalVolume = inv1UserInformation['totalVolume'];
    expect(new BigNumber(inv1UserTotalVolume).isGreaterThan(new BigNumber(0))).to.equal(true)


    // Information about the new user.
    let inv2UserInformation = await rewardsProgram.lpUsers.call(fixedProductMarketMaker.address, investor2);
    let inv2UserTotalVolume = inv2UserInformation['totalVolume'];
    expect(new BigNumber(inv2UserTotalVolume).isEqualTo(new BigNumber(0))).to.equal(true)

    await rewardsProgram.increaseBlockNumber(oneDayBlocks + 1);
    // rewardsDaily
    
    rewards = await rewardsProgram.getLPReward(fixedProductMarketMaker.address, investor1);
    pendingRewards = rewards['pendingRewards'];
    claimedRewards = rewards['claimedRewards'];
    
    expect(new BigNumber(pendingRewards).isGreaterThan(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(pendingRewards).isGreaterThan(new BigNumber(rewardsDaily))).to.equal(true)
    expect(new BigNumber(claimedRewards).isEqualTo(new BigNumber(0))).to.equal(true)

    rewards = await rewardsProgram.getLPReward(fixedProductMarketMaker.address, investor2);
    pendingRewards = rewards['pendingRewards'];
    claimedRewards = rewards['claimedRewards'];
    expect(new BigNumber(pendingRewards).isEqualTo(new BigNumber(0))).to.equal(true)
    expect(new BigNumber(claimedRewards).isEqualTo(new BigNumber(0))).to.equal(true)
  })

  //tradeClaimUserRewards test for this .
  it('Should vote for the approval of this created market', async function() {
  })

})
