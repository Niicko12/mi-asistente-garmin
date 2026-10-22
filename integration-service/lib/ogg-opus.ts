// Codifica PCM de 16 bits mono a Ogg/Opus (RFC 7845), el formato que el
// reloj ya graba y puede reproducir. Opus a ~16 kbps pesa ~2 KB/s: un
// tamaño razonable para el Bluetooth del reloj.

import OpusScript from "opusscript";

const FRAME_MS = 20;
const PACKETS_PER_PAGE = 50;
// Retardo típico del codificador, en muestras a 48 kHz (RFC 7845 §4.2).
const PRE_SKIP = 312;
// El altavoz del reloj hacía un ruido al terminar: entrada y salida suaves
// y un colchón de silencio para que se apague cuando ya no suena nada.
const FADE_IN_MS = 10;
const FADE_OUT_MS = 40;
const TAIL_SILENCE_MS = 300;

export function encodeOggOpus(pcm: Buffer, sampleRate: 8000 | 12000 | 16000 | 24000 | 48000, bitrate = 16000): Buffer {
  // Versión JS pura: el .wasm no entra en el paquete de la función de Vercel.
  const encoder = new OpusScript(sampleRate, 1, OpusScript.Application.VOIP, { wasm: false });
  encoder.setBitrate(bitrate);
  pcm = smoothEdges(pcm, sampleRate);
  const totalSamples = pcm.length / 2;
  const frameSamples = (sampleRate * FRAME_MS) / 1000;
  const frameBytes = frameSamples * 2;
  const samples48PerFrame = (48000 * FRAME_MS) / 1000;

  const packets: Buffer[] = [];
  try {
    for (let offset = 0; offset < pcm.length; offset += frameBytes) {
      let frame = pcm.subarray(offset, offset + frameBytes);
      if (frame.length < frameBytes) {
        frame = Buffer.concat([frame, Buffer.alloc(frameBytes - frame.length)]);
      }
      packets.push(Buffer.from(encoder.encode(frame, frameSamples)));
    }
  } finally {
    encoder.delete();
  }

  const serial = (Math.random() * 0xffffffff) >>> 0;
  const pages: Buffer[] = [
    page([opusHead(sampleRate)], 0n, serial, 0, 0x02),
    page([opusTags()], 0n, serial, 1, 0),
  ];
  // La última página marca las muestras reales (sin el relleno del último
  // fragmento), para que el decodificador no reproduzca de más.
  const total48 = Math.round((totalSamples * 48000) / sampleRate);
  let seq = 2;
  for (let i = 0; i < packets.length; i += PACKETS_PER_PAGE) {
    const chunk = packets.slice(i, i + PACKETS_PER_PAGE);
    const done = i + chunk.length;
    const last = done >= packets.length;
    const granule = BigInt(PRE_SKIP + (last ? total48 : done * samples48PerFrame));
    pages.push(page(chunk, granule, serial, seq++, last ? 0x04 : 0));
  }
  return Buffer.concat(pages);
}

function smoothEdges(input: Buffer, sampleRate: number): Buffer {
  const samples = Math.floor(input.length / 2);
  const tail = Math.round((sampleRate * TAIL_SILENCE_MS) / 1000);
  const out = Buffer.alloc((samples + tail) * 2);
  input.copy(out, 0, 0, samples * 2);
  const fadeIn = Math.min(samples, Math.round((sampleRate * FADE_IN_MS) / 1000));
  const fadeOut = Math.min(samples, Math.round((sampleRate * FADE_OUT_MS) / 1000));
  for (let i = 0; i < fadeIn; i++) {
    out.writeInt16LE(Math.round((out.readInt16LE(i * 2) * i) / fadeIn), i * 2);
  }
  for (let i = 0; i < fadeOut; i++) {
    const at = samples - 1 - i;
    out.writeInt16LE(Math.round((out.readInt16LE(at * 2) * i) / fadeOut), at * 2);
  }
  return out;
}

function opusHead(sampleRate: number): Buffer {
  const head = Buffer.alloc(19);
  head.write("OpusHead", 0, "latin1");
  head[8] = 1; // versión
  head[9] = 1; // canales
  head.writeUInt16LE(PRE_SKIP, 10);
  head.writeUInt32LE(sampleRate, 12);
  head.writeInt16LE(0, 16); // ganancia
  head[18] = 0; // mapeo mono/estéreo
  return head;
}

function opusTags(): Buffer {
  const vendor = Buffer.from("mi-asistente", "latin1");
  const tags = Buffer.alloc(8 + 4 + vendor.length + 4);
  tags.write("OpusTags", 0, "latin1");
  tags.writeUInt32LE(vendor.length, 8);
  vendor.copy(tags, 12);
  tags.writeUInt32LE(0, 12 + vendor.length); // sin comentarios
  return tags;
}

function page(packets: Buffer[], granule: bigint, serial: number, seq: number, flags: number): Buffer {
  const lacing: number[] = [];
  for (const packet of packets) {
    let n = packet.length;
    while (n >= 255) {
      lacing.push(255);
      n -= 255;
    }
    lacing.push(n);
  }
  const header = Buffer.alloc(27 + lacing.length);
  header.write("OggS", 0, "latin1");
  header[4] = 0;
  header[5] = flags;
  header.writeBigInt64LE(granule, 6);
  header.writeUInt32LE(serial, 14);
  header.writeUInt32LE(seq, 18);
  header[26] = lacing.length;
  lacing.forEach((value, i) => (header[27 + i] = value));
  const result = Buffer.concat([header, ...packets]);
  result.writeUInt32LE(crc32(result), 22);
  return result;
}

// CRC de Ogg: polinomio 0x04c11db7 sin reflejar, valor inicial 0.
const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let i = 0; i < 256; i++) {
    let r = i << 24;
    for (let j = 0; j < 8; j++) {
      r = r & 0x80000000 ? (r << 1) ^ 0x04c11db7 : r << 1;
    }
    table[i] = r >>> 0;
  }
  return table;
})();

function crc32(data: Buffer): number {
  let crc = 0;
  for (const byte of data) {
    crc = ((crc << 8) ^ CRC_TABLE[((crc >>> 24) ^ byte) & 0xff]) >>> 0;
  }
  return crc >>> 0;
}
