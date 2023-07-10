// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.9;

import "hardhat/console.sol";

contract UselessTimeBoundToken {
  uint256 period = 120;

  uint256 public totalSupply;

  struct LinkedDelta {
    uint64 pointer;
    int192 delta;
  }

  struct TimeDelta {
    uint64 time;
    int192 delta;
  }

  

  mapping(address => mapping(uint64 => LinkedDelta)) private linkedDeltas;

  function balanceOf(address owner) external view returns (TimeDelta[] memory) {
    uint64 pointer = linkedDeltas[owner][0].pointer;

    uint64 time = uint64(block.timestamp) - (uint64(block.timestamp) % uint64(period));

    uint256 balance;
    uint256 index;
    while (pointer != 0) {
      LinkedDelta memory linkedDelta = linkedDeltas[owner][pointer];
      console.log("loop begin");
      
      if (pointer < time) {
        balance = linkedDelta.delta > 0 ? balance + uint256(uint192(linkedDelta.delta)) : balance - uint256(uint192(-linkedDelta.delta));
        console.log("1 balance::", balance);
        if (balance != 0 && (linkedDelta.pointer == 0 || linkedDelta.pointer > time)) {
          TimeDelta memory timeDelta;
          timeDelta.time = time;
          if (balance > uint192(type(int192).max)) revert ();
          timeDelta.delta = int192(uint192(balance));
          //timeDeltas[index] = timeDelta;
          timeDeltas.push(timeDelta);
          unchecked {
            ++index;
          }
        }
      } else if (pointer == time) {
        balance = linkedDelta.delta > 0 ? balance + uint256(uint192(linkedDelta.delta)) : balance - uint256(uint192(-linkedDelta.delta));
        console.log("2 balance::", balance);

        if (balance != 0) {
          TimeDelta memory timeDelta;
          timeDelta.time = time;
          console.log("criticial");
          if (balance > uint192(type(int192).max)) revert ();
          console.log("no reverts");
          timeDelta.delta = int192(uint192(balance));
          console.log("potential error");
          //timeDeltas[index] = timeDelta;
          timeDeltas.push(timeDelta);
          console.log("Done!");
          unchecked {
            ++index;
          }
        }
      } else {
        TimeDelta memory timeDelta;
        timeDelta.time = pointer;
        timeDelta.delta = linkedDelta.delta;
        //timeDeltas[index] = timeDelta;
        timeDeltas.push(timeDelta);
        unchecked {
          ++index;
        }
      }

      pointer = linkedDelta.pointer;
    }
  }

  function update(address owner) external {
    uint64 pointer = linkedDeltas[owner][0].pointer;

    uint64 time = uint64(block.timestamp) - (uint64(block.timestamp) % uint64(period));

    uint256 balance;
    while (pointer != 0 && pointer <= time) {
      if (pointer < time) {
        LinkedDelta memory linkedDelta = linkedDeltas[owner][pointer];

        balance = linkedDelta.delta > 0 ? balance + uint256(uint192(linkedDelta.delta)) : balance - uint256(uint192(-linkedDelta.delta));

        if (linkedDelta.pointer == 0 || linkedDelta.pointer > time) {
          if (balance == 0) {
            linkedDeltas[owner][0].pointer = linkedDelta.pointer;
          } else {
            LinkedDelta storage linkedDeltaAtTime = linkedDeltas[owner][time];
            linkedDeltaAtTime.pointer = linkedDelta.pointer;
            if (balance > uint192(type(int192).max)) revert ();
            linkedDeltaAtTime.delta = int192(uint192(balance));
            linkedDeltas[owner][0].pointer = time;
          }
        }

        pointer = linkedDelta.pointer;
      } else {
        LinkedDelta storage linkedDeltaAtTime = linkedDeltas[owner][pointer];
        
        balance = linkedDeltaAtTime.delta > 0 ? balance + uint256(uint192(linkedDeltaAtTime.delta)) : balance - uint256(uint192(-linkedDeltaAtTime.delta));

        if (balance == 0) {
          linkedDeltas[owner][0].pointer = linkedDeltaAtTime.pointer;
        } else {
          if (balance > uint192(type(int192).max)) revert ();
          linkedDeltaAtTime.delta = int192(uint192(balance));
          linkedDeltas[owner][0].pointer = time;
        }

        pointer = linkedDeltaAtTime.pointer;
      }
    } 
  }

  function mint(address to, uint256 amount) external {
    if (to == address(0)) revert ();
    if (amount == 0) revert ();

    totalSupply += amount;
    if (totalSupply > uint192(type(int192).max)) revert ();

    uint64 time = uint64(block.timestamp) - (uint64(block.timestamp) % uint64(period));

    uint64 pointer = linkedDeltas[to][0].pointer;

    if (pointer == 0 || pointer > time) {
        LinkedDelta storage linkedDeltaAtTime = linkedDeltas[to][time];
        linkedDeltaAtTime.pointer = pointer;
        if (amount > uint192(type(int192).max)) revert ();
        linkedDeltaAtTime.delta = int192(uint192(amount));
        linkedDeltas[to][0].pointer = time;
    }

    uint256 balance;
    while (pointer != 0 && pointer <= time) {
      if (pointer < time) {
        LinkedDelta memory linkedDelta = linkedDeltas[to][pointer];

        balance = linkedDelta.delta > 0 ? balance + uint256(uint192(linkedDelta.delta)) : balance - uint256(uint192(-linkedDelta.delta));

        if (linkedDelta.pointer == 0 || linkedDelta.pointer > time) {
          if (balance == 0) {
            LinkedDelta storage linkedDeltaAtTime = linkedDeltas[to][time];
            linkedDeltaAtTime.pointer = linkedDelta.pointer;
            if (amount > uint192(type(int192).max)) revert ();
            linkedDeltaAtTime.delta = int192(uint192(amount));
            linkedDeltas[to][0].pointer = time;
          } else {
            LinkedDelta storage linkedDeltaAtTime = linkedDeltas[to][time];
            linkedDeltaAtTime.pointer = linkedDelta.pointer;
            if (balance + amount > uint192(type(int192).max)) revert ();
            linkedDeltaAtTime.delta = int192(uint192(balance + amount));
            linkedDeltas[to][0].pointer = time;
          }
        }

        pointer = linkedDelta.pointer;
      } else {
        LinkedDelta storage linkedDeltaAtTime = linkedDeltas[to][pointer];
        
        balance = linkedDeltaAtTime.delta > 0 ? balance + uint256(uint192(linkedDeltaAtTime.delta)) : balance - uint256(uint192(-linkedDeltaAtTime.delta));

        if (balance == 0) {
          if (amount > uint192(type(int192).max)) revert ();
          linkedDeltaAtTime.delta = int192(uint192(amount));
          linkedDeltas[to][0].pointer = time;
        } else {
          if (balance + amount > uint192(type(int192).max)) revert ();
          linkedDeltaAtTime.delta = int192(uint192(balance + amount));
          linkedDeltas[to][0].pointer = time;
        }

        pointer = linkedDeltaAtTime.pointer;
      }
    } 
  }

  function burn(address to, uint256 amount) external {
    if (to == address(0)) revert ();
    if (amount == 0) revert ();
    
    totalSupply -= amount;

    uint64 time = uint64(block.timestamp) - (uint64(block.timestamp) % uint64(period));

    uint64 pointer = linkedDeltas[msg.sender][0].pointer;

    if (pointer == 0) revert ();

    uint256 balance;
    while (pointer != 0) {
      if (pointer < time) {
        LinkedDelta memory linkedDelta = linkedDeltas[msg.sender][pointer];

        balance = linkedDelta.delta > 0 ? balance + uint256(uint192(linkedDelta.delta)) : balance - uint256(uint192(-linkedDelta.delta));

        if (linkedDelta.pointer == 0 || linkedDelta.pointer > time) {
          if (amount > uint192(type(int192).max)) revert ();
          balance -= amount;

          if (balance == 0) {
            linkedDeltas[msg.sender][0].pointer = linkedDelta.pointer;
          } else {
            LinkedDelta storage linkedDeltaAtTime = linkedDeltas[msg.sender][time];
            linkedDeltaAtTime.delta = int192(uint192(balance));
            linkedDeltaAtTime.pointer = linkedDelta.pointer;
            linkedDeltas[msg.sender][0].pointer = time;
          }
        }

        pointer = linkedDelta.pointer;
      } else if (pointer == time) {
        LinkedDelta storage linkedDeltaAtTime = linkedDeltas[msg.sender][pointer];

        balance = linkedDeltaAtTime.delta > 0 ? balance + uint256(uint192(linkedDeltaAtTime.delta)) : balance - uint256(uint192(-linkedDeltaAtTime.delta));
        balance -= amount;

        if (balance == 0) {
          linkedDeltas[msg.sender][0].pointer = linkedDeltaAtTime.pointer;
        } else {
          linkedDeltaAtTime.delta = int192(uint192(balance));
          linkedDeltas[msg.sender][0].pointer = time;
        }

        pointer = linkedDeltaAtTime.pointer;
      } else {
        LinkedDelta memory linkedDelta = linkedDeltas[msg.sender][pointer];

        balance = linkedDelta.delta > 0 ? balance + uint256(uint192(linkedDelta.delta)) : balance - uint256(uint192(-linkedDelta.delta));

        pointer = linkedDelta.pointer;
      }
    }
  }

  function transfer(address to, uint64 start, uint64 end, uint256 amount) external {
    if (to == address(0)) revert ();
    if (amount == 0) revert ();

    if (start % period != 0) revert ();
    if (end % period != 0) revert ();
    
    uint64 time = uint64(block.timestamp) - (uint64(block.timestamp) % uint64(period));
    if (start < time) start = time;
    if (end < start && end != 0) revert ();

    uint64 pointer = linkedDeltas[msg.sender][0].pointer;

    if (pointer == 0) revert ();

    uint256 balance;
    while (pointer != 0 && pointer <= end) {
      if (pointer < time) {
        LinkedDelta memory linkedDelta = linkedDeltas[msg.sender][pointer];

        balance = linkedDelta.delta > 0 ? balance + uint256(uint192(linkedDelta.delta)) : balance - uint256(uint192(-linkedDelta.delta));

        if (linkedDelta.pointer == 0 || linkedDelta.pointer > time) {
          if (start == time) balance -= amount;
          
          if (balance == 0) {
            if (linkedDelta.pointer == 0) linkedDeltas[msg.sender][0].pointer = end;
            else if (linkedDelta.pointer >= end) {

              linkedDeltas[msg.sender][0].pointer = end;
            }
            
            linkedDeltas[msg.sender][0].pointer = linkedDelta.pointer;
          } else {
            LinkedDelta storage linkedDeltaAtTime = linkedDeltas[msg.sender][time];
            linkedDeltaAtTime.delta = int192(uint192(balance));
            linkedDeltaAtTime.pointer = linkedDelta.pointer;
            linkedDeltas[msg.sender][0].pointer = time;
          }
        }
      }
    }
  }
}
