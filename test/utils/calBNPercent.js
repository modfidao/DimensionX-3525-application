function calBNPercent(base, percent) {
  const denominator = 1000000000;
  const molecule = percent * denominator;
  const result = base.mul(molecule).div(denominator);

  return result;
}

module.exports = calBNPercent