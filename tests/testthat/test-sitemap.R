test_that("parse_sitemap reads a urlset", {
  xml <- xml2::read_xml(
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
       <url><loc>https://x.gov/a</loc><lastmod>2026-01-02</lastmod></url>
       <url><loc>https://x.gov/b</loc><lastmod>2025-06-01</lastmod></url>
     </urlset>'
  )
  out <- parse_sitemap(xml)
  expect_equal(out$type, "urlset")
  expect_equal(out$urls, c("https://x.gov/a", "https://x.gov/b"))
  expect_equal(out$lastmod, c("2026-01-02", "2025-06-01"))
})

test_that("parse_sitemap reads a sitemap index", {
  xml <- xml2::read_xml(
    '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
       <sitemap><loc>https://x.gov/sm1.xml</loc></sitemap>
       <sitemap><loc>https://x.gov/sm2.xml</loc></sitemap>
     </sitemapindex>'
  )
  out <- parse_sitemap(xml)
  expect_equal(out$type, "index")
  expect_equal(length(out$urls), 2L)
})
