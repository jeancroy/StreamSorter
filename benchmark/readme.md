
# Files

## Benchmark
    - Run the sorting algorithms on scandal output that has been stored to a file
    
## Benchmark-live
    - Demo usage with live scandal.
    - Note: There's a lot of timing noise accessing file system, that's why default benchmark is from a recorded session

## Benchmark-record
     - Save scandal output to a compressed dat file
    
     
## stat.coffee
     - Manage time elapsed and stats.
     - `statTimer#log` output the following stats
            - Number of run
            - Average of those run
            - Incertitude on the average because of the number of sample (runs)
                - If incertitude too big, consider doing more run
            - Absolute min sample
            - Absolute max sample
            - Confidence interval where we expect 95% of the runs present or future to lies in.
                - take into account number of sample
                - for a large number of sample, should fit inside absolute min and max
     

     
    