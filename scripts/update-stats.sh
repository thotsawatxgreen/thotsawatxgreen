#!/usr/bin/env bash
# Writes assets/stats.svg with PR, review and yearly contribution totals,
# summed across every account in STATS_LOGINS (space separated).
# Needs GH_TOKEN (or a logged-in gh) that can read the repos to be counted.
# Prints totals only; never prints repo or PR names.
set -euo pipefail

logins="${STATS_LOGINS:-$(gh api user --jq .login)}"
year="$(date -u +%Y)"

authors=""
reviewers=""
not_authors=""
for login in $logins; do
  authors+="+author:${login}"
  reviewers+="+reviewed-by:${login}"
  not_authors+="+-author:${login}"
done

# Qualifiers of the same kind are OR'd by GitHub search, so each PR is counted once.
pull_requests="$(gh api "search/issues?q=type:pr${authors}&per_page=1" --jq .total_count)"
reviews="$(gh api "search/issues?q=type:pr${reviewers}${not_authors}&per_page=1" --jq .total_count)"

contributions=0
for login in $logins; do
  count="$(gh api graphql -f query="{user(login:\"${login}\"){contributionsCollection(from:\"${year}-01-01T00:00:00Z\"){contributionCalendar{totalContributions}}}}" \
    --jq .data.user.contributionsCollection.contributionCalendar.totalContributions)"
  contributions=$((contributions + count))
done

output="$(dirname "$0")/../assets/stats.svg"
cat > "$output" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="480" height="96" viewBox="0 0 480 96" role="img" aria-label="Pull requests ${pull_requests}, reviews ${reviews}, contributions ${year} ${contributions}">
  <style>
    .card { fill: #f6f8fa; }
    .label { font: 400 13px -apple-system, Segoe UI, Helvetica, Arial, sans-serif; fill: #57606a; }
    .value { font: 600 26px -apple-system, Segoe UI, Helvetica, Arial, sans-serif; fill: #1f2328; }
    @media (prefers-color-scheme: dark) {
      .card { fill: #161b22; }
      .label { fill: #8b949e; }
      .value { fill: #e6edf3; }
    }
  </style>
  <rect class="card" x="0" y="0" width="152" height="96" rx="8"/>
  <rect class="card" x="164" y="0" width="152" height="96" rx="8"/>
  <rect class="card" x="328" y="0" width="152" height="96" rx="8"/>
  <text class="label" x="16" y="32">Pull requests</text>
  <text class="value" x="16" y="70">${pull_requests}</text>
  <text class="label" x="180" y="32">Reviews</text>
  <text class="value" x="180" y="70">${reviews}</text>
  <text class="label" x="344" y="32">Contributions ${year}</text>
  <text class="value" x="344" y="70">${contributions}</text>
</svg>
SVG
echo "pull_requests=${pull_requests} reviews=${reviews} contributions=${contributions}"
