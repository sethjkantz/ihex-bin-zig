const std = @import("std");
const allocator = std.heap.page_allocator; //std.mem.Allocator;

//48 65 6c 6c 6f 5f 77 6f 72 6c 64 
pub fn main() !void{

    const test_str: [10]u8 = .{'4','8','6','5','6','c','6','c','6','f'};
    const bin_str = try hexstrtobin(&test_str);
    for(bin_str) |val| {
        std.debug.print("{c}", .{val});
    }
    std.debug.print("\n", .{});
    
}

pub fn decode_record(record: []const u8) []u8{
    //var start_code: u8 = record[0];
    //var byte_count: u8 = record[1];
    //var address: u16 = record[1];
    //var record_type: u8 = record[1];
    //var data: u8 = 0;
    //var checksum: u8 = 0;
    return record[0];
}

/// Returns an inputted string of hex characters as binary string
/// @note assumes hex pairs, will return len/2 array
pub fn hexstrtobin(hex_str: [] const u8) ![]u8{
    //var bin_str: [255]u8 = undefined;
    const left_shift_byte: u8 = 4;
    var i: u32 = 0;
    var index: u32 = 0;

    var bin_str: []u8 = try allocator.alloc(u8, hex_str.len/2);
    errdefer allocator.free(bin_str);

    while (i<hex_str.len) : (i += 2) {
        index = i/2;
        bin_str[index] = hexchartobin(hex_str[i]) << left_shift_byte;
        if((i+1) < hex_str.len){
            bin_str[index] += hexchartobin(hex_str[i+1]);
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
    return ret;
}