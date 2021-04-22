import net, strutils, sequtils

const TIMEOUT = 100 # ms

type ServerStatus* = object
  online*: bool
  name*: string
  players*: int
  max_players*: int

proc parseMinecraftResponse(response: string): (string, int, int) =
  # The response looks like this:
  # [255, 0, 23, 0, name[0], 0, name[1], 0, ..., 0, 0xA7, 0, players[0], 0, ..., 0, 0xA7, 0, max_players[0], ...]
  # So I strip the first 3 chars, filter the 0s and split by 0xA7
  let data = response[3..^1].filter(proc (c: char): bool = ((int)c) != 0).join().split('\xA7')
  let name = data[0]
  let players = data[1].parseInt()
  let max_players = data[2].parseInt()
  result = (name, players, max_players)

proc getServerStatus*(address: string, port: int = 25565, timeout: int = TIMEOUT): ServerStatus =
  var socket = newSocket()
  try:
    socket.connect(address, Port(port))
    socket.send($((char)0xFE))
    let data = socket.recv(256, TIMEOUT)
    if (data[0] == (char)0xFF):
      let parsedData = parseMinecraftResponse(data)
      result.online = true
      result.name = parsedData[0]
      result.players = parsedData[1]
      result.max_players = parsedData[2]
    socket.close()
  except OSError, TimeoutError:
    discard