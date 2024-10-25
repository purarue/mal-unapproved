This has been replaced by [checker_mal](https://github.com/Hiyori-API/checker_mal), which consolidates `mal_id_cache` and this website into the same application

---

A Sinatra website that serves the output of [`mal_id_cache --unapproved json`](https://github.com/purarue/mal-id-cache)

Consists of `cache_loop`, which keeps the JSON cache file up to date and the http server.

##### Install/Run:

After installing `ruby`, `bundle`, and `python3.6+`, `uglifycss`:

Assumes you have a built [`mal_id_cache`](https://github.com/purarue/mal-id-cache). I run that on my server anyways, so you could just set up a script to periodically `git pull` from that repo. Otherwise, run `mal_id_cache --loop` in the background.

Host an instance of jikan on port 8000. See [here](https://github.com/jikan-me/jikan-rest#01-installation-prerequisites) for more info; my [docker setup](https://github.com/purarue/docker-jikan)

Uses `uglifycss` to minify CSS from `./public/raw_css` to `./public/css`. That can be done with `./uglify_css`

```
bundle install
pip3 install --user jikanpy requests
./cache_loop once # (run once to build the initial unapproved/name cache)
./cache_loop & # run in background to keep unapproved IDs updated
ruby server.rb # to serve html
```

I handle the backgrounds tasks using supervisor [here](https://github.com/purarue/vps)
