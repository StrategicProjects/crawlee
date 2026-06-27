test_that("parse_feed reads RSS items", {
  xml <- xml2::read_xml(
    '<rss version="2.0"><channel>
       <item><title>A</title><link>https://x.gov/a</link>
         <pubDate>Mon, 02 Jan 2026 00:00:00 GMT</pubDate></item>
       <item><title>B</title><link>https://x.gov/b</link></item>
     </channel></rss>'
  )
  out <- parse_feed(xml)
  expect_equal(out$urls, c("https://x.gov/a", "https://x.gov/b"))
  expect_equal(out$titles, c("A", "B"))
})

test_that("parse_feed reads Atom entries", {
  xml <- xml2::read_xml(
    '<feed xmlns="http://www.w3.org/2005/Atom">
       <entry><title>A</title><link href="https://x.gov/a"/></entry>
       <entry><title>B</title>
         <link rel="self" href="https://x.gov/self"/>
         <link rel="alternate" href="https://x.gov/b"/></entry>
     </feed>'
  )
  out <- parse_feed(xml)
  expect_equal(out$urls, c("https://x.gov/a", "https://x.gov/b"))
  expect_equal(out$titles, c("A", "B"))
})
