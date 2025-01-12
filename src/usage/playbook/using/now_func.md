# `now` 函数：获取当前时间

*版本 2.3 中新引入*。

Jinja2 的函数 `now()`，会获取到当前时间的一个 Python 日期对象，或一种字符串表示法。

`now()` 函数支持两个参数：

- `utc`
指定为 `True` 可获取 UTC 的当前时间。默认为 `False`。


- `fmt`
接受一个 [`strftime`](https://docs.python.org/3/library/datetime.html#strftime-strptime-behavior) 的字符串，返回一个格式化后的日期时间字符串。

比如：`dtg: "Current time (UTC): {{ now(utc=true,fmt='%Y-%m-%d %H:%M:%S') }}"`
