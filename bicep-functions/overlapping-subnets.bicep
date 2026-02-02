//gist by JKerens
// Check for overlapping subnets in a list of subnets
type SubnetRange = {
  start: int
  end: int
  cidr: string
}

// var subnets = loadJsonContent('subnets.json')

// var addressPrefixes = map(subnets, s => s.addressPrefix)

// var subnetRanges SubnetRange[] = map(addressPrefixes, s => {
//   start: _ipv4ToInt(cidrHost(s, 0))
//   end: _ipv4ToInt(cidrHost(s, _getMaxHosts(parseCidr(s).cidr) - 1))
//   cidr: s
// })

// // hasOverlap = true
// output hasOverlap bool = _rangesHaveOverlap(subnetRanges)

@description('Returns the total usable hosts in a given subnet CIDR (e.g., /24 => 254)')
func _getMaxHosts(cidr int) int =>
  reduce(range(0, (32 - cidr)), 1, (total, _) => total * 2) - 2

// Converts "10.1.2.3" to a 32-bit integer
// integer=(octet_1 * 256^3) + (octet_2 * 256^2) + (octet_3 * 256^1) + (octet_4 * 256^0))
@description('Convert an IPv4 string to integer')
func _ipv4ToInt(ip string) int => 
  int(
    split(ip, '.')[0]) * 256 * 256 * 256 + int(
      split(ip, '.')[1]) * 256 * 256 + int(
        split(ip, '.')[2]) * 256 + int(
          split(ip, '.')[3])

@description('Returns true if two ranges overlap')
func _hasOverlap(a SubnetRange, b SubnetRange) bool => a.start <= b.end && b.start <= a.end

// Safely check for overlaps between all ranges without going out of bounds
// hasOverlap is defaulted to false but set to true if any overlaps are found
func _rangesHaveOverlap(ranges SubnetRange[]) bool =>
reduce(range(0, length(ranges) - 1), false, (hasOverlap, i) =>
  hasOverlap || reduce(range(i + 1, length(ranges)), false, (innerOverlap, j) =>
    innerOverlap || (j < length(ranges) ? _hasOverlap(ranges[i], ranges[j]) : false)
     )
)
