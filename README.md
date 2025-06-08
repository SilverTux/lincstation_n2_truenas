# How to use it

Clone it to your TrueNAS Scale 25.04 and run the run.sh like:

```bash
./run.sh -s 0,0,1,1,1,1,1 -b "rgb(0,255,0)" -m breathe
```

which will turn on the NVME and Networking leds to on and sets the led strip to
breath mode in green color.

### Thanks

I would like to thank these authors their publications, these were very helpful to
start writing the scripts:

https://gist.github.com/albal/f6ea7b2f1a9d7ffc97207a3636928d4f

https://github.com/fmiguelmmartins/lincstation_boot
