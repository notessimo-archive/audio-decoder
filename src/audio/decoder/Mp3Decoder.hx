package audio.decoder;

import haxe.io.Bytes;
import haxe.io.BytesInput;

import format.mp3.Data;
import format.mp3.Tools;

#if js
import browser.BrowserDetect;
#end

/**
 * Simple interface to MP3 Decoder
 *
 * Progressively decode the MP3 by requesting range
 * 
 * JS works but sample point are wayyyy off compared to Flash extract()
 *
 * Will need some major cleanup, mostly experimenting right now...
 */
class Mp3Decoder extends Decoder
{
  // Constructor
  public function new( bytes:Bytes, delay:Bool = false )
  {
    super( bytes, delay );
  }
  
  override function create()
  {
    trace("");
    
    var info = Mp3Utils.getInfo(bytes);
    trace("MP3 Reader finished");
    
    _process( info.length, info.channels, info.sampleRate );
    
    #if js
    // Use Browser DecodeAudioData, at first it seems like CPU usage is down as well as Chrome's "violation"
    if ( BrowserDetect.hasMP3() && Decoder.webAudioEnabled )
    {
      decodeWebAudio();
    }
    #end
  }

  // Read samples inside the MP3
  private override function read(start:Int, end:Int):Bool
  {
    #if js
    if ( BrowserDetect.hasMP3() && Decoder.webAudioEnabled )
    {
      return super.read( start, end );
    }
    #end
    
    // TODO: !!!
    return true;
  }
}

// Modify the MP3 Class a bit so we can get the information a bit more efficiently
typedef Mp3Info =
{
  var sampleRate:Int;
  var channels:Int;
  var length:Int;
};

private class Mp3Utils extends format.mp3.Reader
{
  var bi:BytesInput;
  var channels:Int = 1;
  var sampleRate:Int = 44100;
  
  public function new( i:BytesInput ) 
  {
    bi = i;
    
    super(i);
  }
  
  public override function readFrame():MP3Frame
  {
    var header = readFrameHeader();
    
    if (header == null || Tools.isInvalidFrameHeader(header))
      return null;
    
    channels = header.channelMode == Mono ? 1 : 2;
    
    sampleRate = switch ( header.samplingRate )
    {
      case SR_48000: 48000;
      case SR_44100: 44100;
      case SR_32000: 32000;
      case SR_24000: 24000;
      case SR_22050: 22050;
      case SR_12000: 12000;
      case SR_11025: 11025;
      case SR_8000: 8000;
      default: 44100;
    };
    
    try {
      var length = Tools.getSampleDataSizeHdr(header);
      samples += Tools.getSampleCountHdr(header);
      sampleSize += length;
      
      bi.position += length;
      
      return 
      {
        header: header,
        data: null
      };
    }
    catch ( e:haxe.io.Eof )
    {
      return null;
    }
  }

  public static function getInfo( bytes:Bytes ):Mp3Info
  {
    var reader = new Mp3Utils(new BytesInput(bytes));
    
    reader.readFrames();
    
    return
    {
      sampleRate: reader.sampleRate,
      channels: reader.channels,
      length: reader.samples
    };
  }
}