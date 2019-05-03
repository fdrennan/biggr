library(biggr)
library(stringr)

test_that("user_data return the correct values", {
  user_data <-
    user_data_gen(phone_number = 1111111111,
                  postgres_password = 'postgrespass')

  expect_equal(
     str_detect(user_data,
                '1111111111'),
    TRUE
  )

  expect_equal(
    str_detect(user_data,
               'postgrespass'),
    TRUE
  )
})

test_that("user_data return the correct values when no phone supplied", {
  user_data <-
    user_data_gen(postgres_password = 'postgrespass')

  expect_equal(
    str_detect(user_data,
               '5555555555'),
    TRUE
  )
})

