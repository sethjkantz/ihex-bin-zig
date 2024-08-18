// zig build-exe ihex2bin.zig

const std = @import("std");
const allocator = std.heap.page_allocator; //std.mem.Allocator;
const file_name = "example.hex";
const out_file_name = "test.bin";

// possible record types, unused for now
const RecType = enum(u8) {
    Data = 0, // byte count defines data length
    EOF = 1, // byte count and address file is 0
    ExtendedSegAddress = 2, // byte count always 2, ignore addr field, data is *16 + following data to ensure
    StartSegAddress = 3,
    ExtendedLinearAddress = 4,
    StartLinearAddress = 5,
    other
};

// Record to be read in
const Record = struct{
    byte_count: u8 = 0,
    address: u16 = 0,
    record_type: u8 = 1, // default to EOF
    data: []u8 = undefined,
    checksum: u8 = 0
};
const MIN_REC_LENGTH = 5;

// 48 65 6c 6c 6f 5f 77 6f 72 6c 64 
pub fn main() !void{

    try decode_ihex_file(file_name, out_file_name);
    
}

/// Opens file named in_file and reads intel hex
/// Writes raw binary to file given out_file name
/// disregards address for now, assumes starting at 0
pub fn decode_ihex_file(in_file: [] const u8, out_file: [] const u8) !void{
    // output file vals
    const outfile = try std.fs.cwd().createFile(out_file, .{ .read = true });
    defer outfile.close();
    
    // input file vals
    var file = try std.fs.cwd().openFile(in_file, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();
    var buf: [2056]u8 = undefined;

    // Decode record line by line
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.debug.print("{s}", .{line});
        std.debug.print("\n", .{});
        const out_val: Record = try decode_record(line);

        // add converted outfile to .bin, if valid
        if (out_val.record_type == 0){
            std.debug.print("Writing... addr={d}, len={d} \n", .{out_val.address, out_val.data.len});
            _ = try outfile.writeAll(out_val.data);
        }
    }
}

pub fn decode_record(record: []const u8) !Record{
    // const locations to read, disregard start character
    const hex_start: usize = 1;
    const hex_end: usize = record.len - 1;
    
    // get binary values from ascii string
    const conv_rec: []u8 = try hexstrtobin(record[hex_start..hex_end]);
    
    // Locations via intel hex format
    const byte_count_loc: usize = 0;
    const upper_addr_loc: usize = 1;
    const lower_addr_loc: usize = 2;
    const rec_type_loc: usize = 3;
    const data_start: usize = 4;
    const data_end: usize = conv_rec.len-2;
    const checksum_loc: usize = conv_rec.len-1;
    
    var rec_val: Record = Record{};

    if (conv_rec.len >= MIN_REC_LENGTH){
        rec_val.byte_count = conv_rec[byte_count_loc];
        rec_val.address = (@as(u16,@intCast(conv_rec[upper_addr_loc])) << 8) | @as(u16,@intCast(conv_rec[lower_addr_loc]));
        rec_val.record_type = conv_rec[rec_type_loc];
        rec_val.data = undefined;
        rec_val.checksum = conv_rec[checksum_loc];
    }

    if(conv_rec.len > MIN_REC_LENGTH){
        rec_val.data = conv_rec[data_start..data_end];
    }  

    return rec_val;
}

/// Returns an even inputted string of hex characters as len/2 binary array
/// assumes hex pairs
pub fn hexstrtobin(hex_str: [] const u8) ![]u8{
    const left_shift_byte: u8 = 4;
    var i: u32 = 0;
    var index: u32 = 0;

    var bin_str: []u8 = try allocator.alloc(u8, hex_str.len/2);
    errdefer allocator.free(bin_str);

    while (i<hex_str.len) : (i += 2) {
        index = i/2;
        bin_str[index] = hexchartobin(hex_str[i]) << left_shift_byte;
        
        // odd length shouldn't happen, but check here just in case
        if((i+1) < hex_str.len){
            bin_str[index] |= hexchartobin(hex_str[i+1]);
        }
    }
    return bin_str;
}

/// Returns single character (nibble) of hex to bin 
pub fn hexchartobin(hex_char: u8) u8 {
    var ret: u8 = 0;
    if(hex_char >= '0' and hex_char <= '9'){
        ret = hex_char - '0';
    } else if( hex_char >= 'a' and hex_char <= 'f'){
        ret = hex_char - 'a' + 10;
    } else if( hex_char >= 'A' and hex_char <= 'F'){
        ret = hex_char - 'A' + 10;
    }
    return (ret & 0x0F);
}