/*
* NeuQuant Neural-Net Quantization Algorithm
* ------------------------------------------
* 
* Copyright (c) 1994 Anthony Dekker
* 
* NEUQUANT Neural-Net quantization algorithm by Anthony Dekker, 1994. See
* "Kohonen neural networks for optimal colour quantization" in "Network:
* Computation in Neural Systems" Vol. 5 (1994) pp 351-367. for a discussion of
* the algorithm.
* 
* Any party obtaining a copy of these files from the author, directly or
* indirectly, is granted, free of charge, a full and unrestricted irrevocable,
* world-wide, paid up, royalty-free, nonexclusive right and license to deal in
* this software and documentation files (the "Software"), including without
* limitation the rights to use, copy, modify, merge, publish, distribute,
* sublicense, and/or sell copies of the Software, and to permit persons who
* receive copies from any such party to do so, with the only requirement being
* that this copyright notice remain intact.
*/

/*
* This class handles Neural-Net quantization algorithm
* @author Kevin Weiner (original Java version - kweiner@fmsware.com)
* @author Thibault Imbert (AS3 version - bytearray.org)
* @version 0.1 AS3 implementation
*/

package org.bytearray.gif.encoder;

import nme.errors.Error;
import nme.utils.ByteArray;

class NeuQuant
{
    private static inline var NETSIZE:Int = 256; /* number of colours used */

    /* four primes near 500 - assume no image has a length so large */
    /* that it is divisible by all four primes */

    private static inline var PRIME1:Int = 499;
    private static inline var PRIME2:Int = 491;
    private static inline var PRIME3:Int = 487;
    private static inline var PRIME4:Int = 503;
    private static inline var MIN_PICTURE_BYTES:Int = (3 * PRIME4);

    /* minimum size for input image */
    /*
    * Program Skeleton ---------------- [select samplefac in range 1..30] [read
    * image from input file] pic = (unsigned char*) malloc(3*width*height);
    * initnet(pic,3*width*height,samplefac); learn(); unbiasnet(); [write output
    * image header, using writecolourmap(f)] inxbuild(); write output image using
    * inxsearch(b,g,r)
    */

    /*
    * Network Definitions -------------------
    */

    private static inline var MAXNETPOS:Int = (NETSIZE - 1);
    private static inline var NETBIASSHIFT:Int = 4; /* bias for colour values */
    private static inline var NCYCLES:Int = 100; /* no. of learning cycles */

    /* defs for freq and bias */
    private static inline var INTBIASSHIFT:Int = 16; /* bias for fractions */
    private static inline var INTBIAS:Int = (1 << INTBIASSHIFT);
    private static inline var GAMMASHIFT:Int = 10; /* gamma = 1024 */
    private static inline var GAMMA:Int = (1 << GAMMASHIFT);
    private static inline var BETASHIFT:Int = 10;
    private static inline var BETA:Int = (INTBIAS >> BETASHIFT); /* beta = 1/1024 */
    private static inline var BETAGAMMA:Int = (INTBIAS << (GAMMASHIFT - BETASHIFT));

    /* defs for decreasing radius factor */
    private static inline var INIT_RAD:Int = (NETSIZE >> 3); /*
                                                         * for 256 cols, radius
                                                         * starts
                                                         */

    private static inline var RADIUS_BIAS_SHIFT:Int = 6; /* at 32.0 biased by 6 bits */
    private static inline var RADIUS_BIAS:Int = (1 << RADIUS_BIAS_SHIFT);
    private static inline var INIT_RADIUS:Int = (INIT_RAD * RADIUS_BIAS); /*
                                                                   * and
                                                                   * decreases
                                                                   * by a
                                                                   */

    private static inline var RADIUS_DEC:Int = 30; /* factor of 1/30 each cycle */

    /* defs for decreasing alpha factor */
    private static inline var ALPHA_BIAS_SHIFT:Int = 10; /* alpha starts at 1.0 */
    private static inline var INIT_ALPHA:Int = (1 << ALPHA_BIAS_SHIFT);
    private var alphadec:Int; /* biased by 10 bits */

    /* radbias and alpharadbias used for radpower calculation */
    private static inline var RAD_BIAS_SHIFT:Int = 8;
    private static inline var RAD_BIAS:Int = (1 << RAD_BIAS_SHIFT);
    private static inline var ALPHA_RAD_BSHIFT:Int = (ALPHA_BIAS_SHIFT + RAD_BIAS_SHIFT);

    private static inline var ALPHA_RAD_BIAS:Int = (1 << ALPHA_RAD_BSHIFT);

    /*
    * Types and Global Variables --------------------------
    */

    private var thepicture:ByteArray;/* the input image itself */
    private var lengthcount:Int; /* lengthcount = H*W*3 */
    private var samplefac:Int; /* sampling factor 1..30 */

    // typedef Int pixel[4]; /* BGRc */
    private var network:Array<Array<Int>>; /* the network itself - [netsize][4] */
    private var netindex:Array<Int>; //new Array();

    /* for network lookup - really 256 */
    private var bias:Array<Int>; //new Array();

    /* bias and freq arrays for learning */
    private var freq:Array<Int>; //new Array();
    private var radpower:Array<Int>; //new Array();

    public function new(thepic:ByteArray, len:Int, sample:Int)
    {

        var i:Int;
        var p:Array<Int>;

        thepicture = thepic;
        lengthcount = len;
        samplefac = sample;

        network = []; //new Array(netsize);
        netindex = [];
        bias = [];
        freq = [];
        radpower = [];

        for (i in 0...NETSIZE)
        {

            p = network[i] = []; //new Array(4);
            p[0] = p[1] = p[2] = Std.int((i << (NETBIASSHIFT + 8)) / NETSIZE);
            p[3] = i;
            freq[i] = Std.int(INTBIAS / NETSIZE); /* 1/netsize */
            bias[i] = 0;
        }

    }

    private function colorMap():ByteArray
    {

#if (flash || html5)
        var map:ByteArray = new ByteArray();
        map.length = netsize * 3;
#else
        var map:ByteArray = new ByteArray(NETSIZE * 3);
#end
        var index:Array<Int> = []; //new Array(netsize);
        for (i in 0...NETSIZE)
          index[network[i][3]] = i;
        var k:Int = 0;
        for (l in 0...NETSIZE) {
          var j:Int = index[l];
          map[k++] = (network[j][0]);
          map[k++] = (network[j][1]);
          map[k++] = (network[j][2]);
        }
        return map;

    }

    /*
   * Insertion sort of network and building of netindex[0..255] (to do after
   * unbias)
   * -------------------------------------------------------------------------------
   */

   private function inxbuild():Void
   {

      var i:Int;
      var j:Int;
      var smallpos:Int;
      var smallval:Int;
      var p:Array<Int>;
      var q:Array<Int>;
      var previouscol:Int;
      var startpos:Int;

      previouscol = 0;
      startpos = 0;
      for (i in 0...NETSIZE)
      {

          p = network[i];
          smallpos = i;
          smallval = p[1]; /* index on g */
          /* find smallest in i..netsize-1 */
          for (j in (i + 1)...NETSIZE)
          {
              q = network[j];
              if (q[1] < smallval)
              { /* index on g */

                smallpos = j;
                smallval = q[1]; /* index on g */
            }
          }

          q = network[smallpos];
          /* swap p (i) and q (smallpos) entries */

          if (i != smallpos)
          {

              j = q[0];
              q[0] = p[0];
              p[0] = j;
              j = q[1];
              q[1] = p[1];
              p[1] = j;
              j = q[2];
              q[2] = p[2];
              p[2] = j;
              j = q[3];
              q[3] = p[3];
              p[3] = j;

          }

          /* smallval entry is now in position i */

          if (smallval != previouscol)

          {

            netindex[previouscol] = (startpos + i) >> 1;

            for (j in (previouscol + 1)...smallval) netindex[j] = i;

            previouscol = smallval;
            startpos = i;

          }

        }

        netindex[previouscol] = (startpos + MAXNETPOS) >> 1;
        for (j in (previouscol + 1)...256) netindex[j] = MAXNETPOS; /* really 256 */

   }

   /*
   * Main Learning Loop ------------------
   */

   private function learn():Void

   {

       var i:Int;
       var j:Int;
       var b:Int;
       var g:Int;
       var r:Int;
       var radius:Int;
       var rad:Int;
       var alpha:Int;
       var step:Int;
       var delta:Int;
       var samplepixels:Int;
       var p:ByteArray;
       var pix:Int;
       var lim:Int;

       if (lengthcount < MIN_PICTURE_BYTES) samplefac = 1;

       alphadec = 30 + Std.int((samplefac - 1) / 3);
       p = thepicture;
       pix = 0;
       lim = lengthcount;
       samplepixels = Std.int(lengthcount / (3 * samplefac));
       delta = Std.int(samplepixels / NCYCLES);
       alpha = INIT_ALPHA;
       radius = INIT_RADIUS;

       rad = radius >> RADIUS_BIAS_SHIFT;
       if (rad <= 1) rad = 0;

       for (i in 0...rad) radpower[i] = alpha * Std.int(((rad * rad - i * i) * RAD_BIAS) / (rad * rad));


       if (lengthcount < MIN_PICTURE_BYTES) step = 3;

       else if ((lengthcount % PRIME1) != 0) step = 3 * PRIME1;

       else

       {

           if ((lengthcount % PRIME2) != 0) step = 3 * PRIME2;

           else

           {

               if ((lengthcount % PRIME3) != 0) step = 3 * PRIME3;

               else step = 3 * PRIME4;

           }

       }

       i = 0;

       while (i < samplepixels)

       {

           b = (p[pix + 0] & 0xff) << NETBIASSHIFT;
           g = (p[pix + 1] & 0xff) << NETBIASSHIFT;
           r = (p[pix + 2] & 0xff) << NETBIASSHIFT;
           j = contest(b, g, r);

           altersingle(alpha, j, b, g, r);

           if (rad != 0) alterneigh(rad, j, b, g, r); /* alter neighbours */

           pix += step;

           if (pix >= lim) pix -= lengthcount;

           i++;

           if (delta == 0) delta = 1;

           if (i % delta == 0)

           {

               alpha -= Std.int(alpha / alphadec);
               radius -= Std.int(radius / RADIUS_DEC);
               rad = radius >> RADIUS_BIAS_SHIFT;

               if (rad <= 1) rad = 0;

               for (j in 0...rad) radpower[j] = alpha * Std.int(((rad * rad - j * j) * RAD_BIAS) / (rad * rad));

           }

       }

   }

   /*
   ** Search for BGR values 0..255 (after net is unbiased) and return colour
   * index
   * ----------------------------------------------------------------------------
   */

   public function map(b:Int, g:Int, r:Int):Int

   {

       var i:Int;
       var j:Int;
       var dist:Int;
       var a:Int;
       var bestd:Int;
       var p:Array<Int>;
       var best:Int;

       bestd = 1000; /* biggest possible dist is 256*3 */
       best = -1;
       i = netindex[g]; /* index on g */
       j = i - 1; /* start at netindex[g] and work outwards */

    while ((i < NETSIZE) || (j >= 0))

    {

        if (i < NETSIZE)

        {

            p = network[i];

            dist = p[1] - g; /* inx key */

            if (dist >= bestd) i = NETSIZE; /* stop iter */

            else

            {

                i++;

                if (dist < 0) dist = -dist;

                a = p[0] - b;

                if (a < 0) a = -a;

                dist += a;

                if (dist < bestd)

                {

                    a = p[2] - r;

                    if (a < 0) a = -a;

                    dist += a;

                    if (dist < bestd)

                    {

                        bestd = dist;
                        best = p[3];

                    }

                }

            }

        }

      if (j >= 0)
      {

          p = network[j];

          dist = g - p[1]; /* inx key - reverse dif */

          if (dist >= bestd) j = -1; /* stop iter */

          else
          {

              j--;
              if (dist < 0) dist = -dist;
              a = p[0] - b;
              if (a < 0) a = -a;
              dist += a;

              if (dist < bestd)

              {

                  a = p[2] - r;
                  if (a < 0)a = -a;
                  dist += a;
                  if (dist < bestd)
                  {
                      bestd = dist;
                      best = p[3];
                  }

              }

          }

      }

    }

    return (best);

  }

  public function process():ByteArray
  {

    learn();
    unbiasnet();
    inxbuild();
    return colorMap();

  }

  /*
  * Unbias network to give byte values 0..255 and record position i to prepare
  * for sort
  * -----------------------------------------------------------------------------------
  */

  private function unbiasnet():Void

  {

    var i:Int;
    var j:Int;

    for (i in 0...NETSIZE)
    {
      network[i][0] >>= NETBIASSHIFT;
      network[i][1] >>= NETBIASSHIFT;
      network[i][2] >>= NETBIASSHIFT;
      network[i][3] = i; /* record colour no */
    }

  }

  /*
  * Move adjacent neurons by precomputed alpha*(1-((i-j)^2/[r]^2)) in
  * radpower[|i-j|]
  * ---------------------------------------------------------------------------------
  */

  private function alterneigh(rad:Int, i:Int, b:Int, g:Int, r:Int):Void

  {

      var j:Int;
      var k:Int;
      var lo:Int;
      var hi:Int;
      var a:Int;
      var m:Int;

      var p:Array<Int>;

      lo = i - rad;
      if (lo < -1) lo = -1;

      hi = i + rad;

      if (hi > NETSIZE) hi = NETSIZE;

      j = i + 1;
      k = i - 1;
      m = 1;

      while ((j < hi) || (k > lo))

      {

          a = radpower[m++];

          if (j < hi)

          {

              p = network[j++];

              try {

                  p[0] -= Std.int((a * (p[0] - b)) / ALPHA_RAD_BIAS);
                  p[1] -= Std.int((a * (p[1] - g)) / ALPHA_RAD_BIAS);
                  p[2] -= Std.int((a * (p[2] - r)) / ALPHA_RAD_BIAS);

                  } catch (e:Error) {} // prevents 1.3 miscompilation

            }

            if (k > lo)

            {

                p = network[k--];

                try
                {

                    p[0] -= Std.int((a * (p[0] - b)) / ALPHA_RAD_BIAS);
                    p[1] -= Std.int((a * (p[1] - g)) / ALPHA_RAD_BIAS);
                    p[2] -= Std.int((a * (p[2] - r)) / ALPHA_RAD_BIAS);

                } catch (e:Error) {}

            }

      }

  }

  /*
  * Move neuron i towards biased (b,g,r) by factor alpha
  * ----------------------------------------------------
  */

  private function altersingle(alpha:Int, i:Int, b:Int, g:Int, r:Int):Void
  {

      /* alter hit neuron */
      var n:Array<Int> = network[i];
      n[0] -= Std.int((alpha * (n[0] - b)) / INIT_ALPHA);
      n[1] -= Std.int((alpha * (n[1] - g)) / INIT_ALPHA);
      n[2] -= Std.int((alpha * (n[2] - r)) / INIT_ALPHA);

  }

  /*
  * Search for biased BGR values ----------------------------
  */

  private function contest(b:Int, g:Int, r:Int):Int
  {

      /* finds closest neuron (min dist) and updates freq */
      /* finds best neuron (min dist-bias) and returns position */
      /* for frequently chosen neurons, freq[i] is high and bias[i] is negative */
      /* bias[i] = gamma*((1/netsize)-freq[i]) */

      var i:Int;
      var dist:Int;
      var a:Int;
      var biasdist:Int;
      var betafreq:Int;
      var bestpos:Int;
      var bestbiaspos:Int;
      var bestd:Int;
      var bestbiasd:Int;
      var n:Array<Int>;

      bestd = ~(1 << 31);
      bestbiasd = bestd;
      bestpos = -1;
      bestbiaspos = bestpos;

      for (i in 0...NETSIZE)

      {

          n = network[i];
          dist = n[0] - b;

          if (dist < 0) dist = -dist;

          a = n[1] - g;

          if (a < 0) a = -a;

          dist += a;

          a = n[2] - r;

          if (a < 0) a = -a;

          dist += a;

          if (dist < bestd)

          {

              bestd = dist;
              bestpos = i;

          }

          biasdist = dist - ((bias[i]) >> (INTBIASSHIFT - NETBIASSHIFT));

          if (biasdist < bestbiasd)

          {

              bestbiasd = biasdist;
              bestbiaspos = i;

          }

          betafreq = (freq[i] >> BETASHIFT);
          freq[i] -= betafreq;
          bias[i] += (betafreq << GAMMASHIFT);

      }

      freq[bestpos] += BETA;
      bias[bestpos] -= BETAGAMMA;
      return (bestbiaspos);

  }

}
