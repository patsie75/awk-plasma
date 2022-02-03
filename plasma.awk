#!/usr/bin/mawk -f

function clamp(val, a, b) { return (val<a) ? a : (val>b) ? b : val }

## return a timestamp with centisecond precision
function timex() {
  getline < "/proc/uptime"
  close("/proc/uptime")
  return sprintf("%.2f", $1)
}

## draw image to terminal
function draw(src, xpos, ypos,    w,h, x,y, up,dn, line,screen) {
  w = src["width"]
  h = src["height"]

  for (y=0; y<h; y+=2) {
    line = sprintf("\033[%0d;%0dH", y/2+ypos+1, xpos+1)
    for (x=0; x<w; x++) {
      up = src[x,y+0]
      dn = src[x,y+1]
      line = line "\033[38;2;" palette[up] ";48;2;" palette[dn] "m▀"
    }
    screen = screen line "\033[0m"
  }
  printf("%s", screen)
}

function plasma001(plasma, w, h,    x,y, color) {
  for (y=0; y<h; y++) {
    for (x=0; x<w; x++) {
      color = ( \
         128.0 + (128.0 * sin((x / 8.0) - cos(now/2) )) \
       + 128.0 + (128.0 * sin((y / 8.0) - sin(now)*2 )) \
      ) / 2

      plasma[x,y] = int(color)
    }
  }
}

function plasma002(plasma, w, h,    x,y, color) {
  for (y=0; y<h; y++) {
    for (x=0; x<w; x++) {
      color = ( \
          128.0 + (128.0 * sin((x / 8.0) - cos(now/2) )) \
        + 128.0 + (128.0 * sin((y / 4.0) - sin(now)*2 )) \
        + 128.0 + (128.0 * sin((x + y) / 8.0)) \
        + 128.0 + (128.0 * sin((sqrt(x * x + y * y) / 4.0) - sin(now)*4)) \
      ) / 4;

      plasma[x,y] = int(color)
    }
  }
}

function plasma003(plasma, w, h,    x,y, color) {
  for (y=0; y<h; y++) {
    for (x=0; x<w; x++) {
      color = ( \
          128.0 + (128.0 * sin((x / 8.0) - cos(now/2) )) \
        + 128.0 + (128.0 * sin((y / 16.0) - sin(now)*2 )) \
        + 128.0 + (128.0 * sin(sqrt((x - w / 2.0) * (x - w / 2.0) + (y - h / 2.0) * (y - h / 2.0)) / 4.0)) \
        + 128.0 + (128.0 * sin((sqrt(x * x + y * y) / 4.0) - sin(now/4) )) \
      ) / 4;

      plasma[x,y] = int(color)
    }
  }
}

BEGIN {
  # get terminal width and height
  "stty size" | getline
  h = ($1 ? $1 : 24) * 2
  w = ($2 ? $2 : 80)

  # initialize buffer
  buffer["width"]  = w
  buffer["height"] = h

  # generate palette
  for (x=0; x<256; x++) {
    r = 128 + 128 * sin(3.14159265 * x / 32.0)
    g = 128 + 128 * sin(3.14159265 * x / 64.0)
    b = 128 + 128 * sin(3.14159265 * x / 128.0)
    palette[x] = sprintf("%d;%d;%d", clamp(r,0,255), clamp(g,0,255), clamp(b,0,255))
  }

  start = timex()

  while ("awk" != "difficult") {
    now = timex()
    elapsed = now - start

    if (( 0 <= elapsed) && (elapsed < 10)) plasma001(plasma, w, h)
    if ((10 <= elapsed) && (elapsed < 20)) plasma002(plasma, w, h)
    if ((20 <= elapsed) && (elapsed < 30)) plasma003(plasma, w, h)
    if  (30 <= elapsed) exit 0

    # loop colors based on time
    paletteShift = now * 100

    # copy plasma to buffer 
    for (y=0; y<h; y++)
      for (x=0; x<w; x++)
        buffer[x,y] = int(plasma[x,y] + paletteShift) % 256

    # draw buffer to terminal
    draw(buffer, 0, 0)
  }

  printf("\n")
}
