
<!-- README.md is generated from README.Rmd. Please edit that file -->
dplyr <img src="man/figures/logo.png" align="right" />
======================================================

[![Build Status](https://travis-ci.org/tidyverse/dplyr.svg?branch=master)](https://travis-ci.org/tidyverse/dplyr) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/tidyverse/dplyr?branch=master&svg=true)](https://ci.appveyor.com/project/tidyverse/dplyr) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/dplyr)](http://cran.r-project.org/package=dplyr) [![Coverage Status](https://img.shields.io/codecov/c/github/tidyverse/dplyr/master.svg)](https://codecov.io/github/tidyverse/dplyr?branch=master)

dplyr is the next iteration of plyr, focussed on tools for working with data frames (hence the `d` in the name). It has three main goals:

-   Identify the most important data manipulation tools needed for data analysis and make them easy to use from R.

-   Provide blazing fast performance for in-memory data by writing key pieces in [C++](http://www.rcpp.org/).

-   Use the same interface to work with data no matter where it's stored, whether in a data frame, a data table or database.

You can install:

-   the latest released version from CRAN with

    ``` r
    install.packages("dplyr")
    ```

-   the latest development version from github with

    ``` r
    if (packageVersion("devtools") < 1.6) {
      install.packages("devtools")
    }
    devtools::install_github("tidyverse/lazyeval")
    devtools::install_github("tidyverse/dplyr")
    ```

You'll probably also want to install the data packages used in most examples: `install.packages(c("nycflights13", "Lahman"))`.

If you encounter a clear bug, please file a minimal reproducible example on [github](https://github.com/tidyverse/dplyr/issues). For questions and other discussion, please use the [manipulatr mailing list](https://groups.google.com/group/manipulatr).

Learning dplyr
--------------

To get started, read the notes below, then read the intro vignette: `vignette("introduction", package = "dplyr")`. To make the most of dplyr, I also recommend that you familiarise yourself with the principles of [tidy data](http://vita.had.co.nz/papers/tidy-data.html): this will help you get your data into a form that works well with dplyr, ggplot2 and R's many modelling functions.

If you need more help, I recommend the following (paid) resources:

-   [dplyr](https://www.datacamp.com/courses/dplyr) on datacamp, by Garrett Grolemund. Learn the basics of dplyr at your own pace in this interactive online course.

-   [Introduction to Data Science with R](http://shop.oreilly.com/product/0636920034834.do): How to Manipulate, Visualize, and Model Data with the R Language, by Garrett Grolemund. This O'Reilly video series will teach you the basics needed to be an effective analyst in R.

Key data structures
-------------------

The key object in dplyr is a *tbl*, a representation of a tabular data structure. Currently `dplyr` supports:

-   data frames
-   [data tables](https://github.com/Rdatatable/data.table/wiki)
-   [SQLite](http://sqlite.org/)
-   [PostgreSQL](http://www.postgresql.org/)/[Redshift](http://aws.amazon.com/redshift/)
-   [MySQL](http://www.mysql.com/)/[MariaDB](https://mariadb.com/)
-   [Bigquery](https://developers.google.com/bigquery/)
-   [MonetDB](http://www.monetdb.org/)
-   data cubes with arrays (partial implementation)

You can create them as follows:

``` r
library(dplyr) # for functions
library(nycflights13) # for data
flights
#> # A tibble: 336,776 × 19
#>     year month   day dep_time sched_dep_time dep_delay arr_time
#>    <int> <int> <int>    <int>          <int>     <dbl>    <int>
#> 1   2013     1     1      517            515         2      830
#> 2   2013     1     1      533            529         4      850
#> 3   2013     1     1      542            540         2      923
#> 4   2013     1     1      544            545        -1     1004
#> 5   2013     1     1      554            600        -6      812
#> 6   2013     1     1      554            558        -4      740
#> 7   2013     1     1      555            600        -5      913
#> 8   2013     1     1      557            600        -3      709
#> 9   2013     1     1      557            600        -3      838
#> 10  2013     1     1      558            600        -2      753
#> # ... with 336,766 more rows, and 12 more variables: sched_arr_time <int>,
#> #   arr_delay <dbl>, carrier <chr>, flight <int>, tailnum <chr>,
#> #   origin <chr>, dest <chr>, air_time <dbl>, distance <dbl>, hour <dbl>,
#> #   minute <dbl>, time_hour <dttm>

# Caches data in local SQLite db
flights_db1 <- tbl(dbplyr::nycflights13_sqlite(), "flights")

# Caches data in local postgres db
flights_db2 <- tbl(dbplyr::nycflights13_postgres(host = "localhost"), "flights")
```

Each tbl also comes in a grouped variant which allows you to easily perform operations "by group":

``` r
carriers_df  <- flights %>% group_by(carrier)
carriers_db1 <- flights_db1 %>% group_by(carrier)
carriers_db2 <- flights_db2 %>% group_by(carrier)
```

Single table verbs
------------------

`dplyr` implements the following verbs useful for data manipulation:

-   `select()`: focus on a subset of variables
-   `filter()`: focus on a subset of rows
-   `mutate()`: add new columns
-   `summarise()`: reduce each group to a smaller number of summary statistics
-   `arrange()`: re-order the rows

They all work as similarly as possible across the range of data sources. The main difference is performance:

``` r
system.time(carriers_df %>% summarise(delay = mean(arr_delay)))
#>    user  system elapsed 
#>   0.050   0.000   0.051
system.time(carriers_db1 %>% summarise(delay = mean(arr_delay)) %>% collect())
#>    user  system elapsed 
#>   0.231   0.143   0.376
system.time(carriers_db2 %>% summarise(delay = mean(arr_delay)) %>% collect())
#>    user  system elapsed 
#>   0.011   0.000   0.131
```

Data frame methods are much much faster than the plyr equivalent. The database methods are slower, but can work with data that don't fit in memory.

``` r
system.time(plyr::ddply(flights, "carrier", plyr::summarise,
  delay = mean(arr_delay, na.rm = TRUE)))
#>    user  system elapsed 
#>   0.115   0.037   0.153
```

Multiple table verbs
--------------------

As well as verbs that work on a single tbl, there are also a set of useful verbs that work with two tbls at a time: joins and set operations.

dplyr implements the four most useful joins from SQL:

-   `inner_join(x, y)`: matching x + y
-   `left_join(x, y)`: all x + matching y
-   `semi_join(x, y)`: all x with match in y
-   `anti_join(x, y)`: all x without match in y

And provides methods for:

-   `intersect(x, y)`: all rows in both x and y
-   `union(x, y)`: rows in either x or y
-   `setdiff(x, y)`: rows in x, but not y

Plyr compatibility
------------------

You'll need to be a little careful if you load both plyr and dplyr at the same time. I'd recommend loading plyr first, then dplyr, so that the faster dplyr functions come first in the search path. By and large, any function provided by both dplyr and plyr works in a similar way, although dplyr functions tend to be faster and more general.

Related approaches
------------------

-   [Blaze](http://blaze.pydata.org)
-   [|Stat](http://oldwww.acm.org/perlman/stat/)
-   [Pig](http://dx.doi.org/10.1145/1376616.1376726)
