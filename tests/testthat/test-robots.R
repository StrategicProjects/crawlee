robots_txt <- "
User-agent: *
Disallow: /private
Allow: /private/public
Crawl-delay: 2

User-agent: crawlee-R
Disallow: /secret
"

test_that("parse_robots groups rules by agent", {
  recs <- parse_robots(robots_txt)
  expect_equal(length(recs), 2L)
  star <- robots_select(recs, "SomeBot/1.0")
  expect_true("*" %in% star$agents)
  expect_equal(star$crawl_delay, 2)
})

test_that("robots_select prefers the specific agent", {
  recs <- parse_robots(robots_txt)
  mine <- robots_select(recs, "crawlee-R (+https://example.org)")
  expect_true("crawlee-r" %in% mine$agents)
})

test_that("robots_path_allowed honours longest-match and Allow override", {
  star <- robots_select(parse_robots(robots_txt), "SomeBot")
  expect_false(robots_path_allowed("/private/x", star))
  expect_true(robots_path_allowed("/private/public/x", star)) # Allow wins
  expect_true(robots_path_allowed("/open", star))
})

test_that("robots_match supports wildcards and end-anchors", {
  expect_true(robots_match("/a/*/c", "/a/b/c"))
  expect_true(robots_match("/x$", "/x"))
  expect_false(robots_match("/x$", "/x/y"))
})

test_that("empty robots allows everything", {
  expect_true(robots_path_allowed("/anything", robots_select(parse_robots(""), "bot")))
})
