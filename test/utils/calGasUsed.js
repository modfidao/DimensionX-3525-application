// cal gas used in translation
async function calGasUsed(txFunc) {
  const tx = await txFunc();
  const txCal = await tx.wait();

  const gasUsed = txCal.cumulativeGasUsed.mul(txCal.effectiveGasPrice);

  return gasUsed;
}

module.exports = calGasUsed;
