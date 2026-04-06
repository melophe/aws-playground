locals {
  stages = {
    dev = {
      throttling_rate_limit  = 10
      throttling_burst_limit = 5
    }
    stag = {
      throttling_rate_limit  = 100
      throttling_burst_limit = 50
    }
    prod = {
      throttling_rate_limit  = 1000
      throttling_burst_limit = 500
    }
  }
}
