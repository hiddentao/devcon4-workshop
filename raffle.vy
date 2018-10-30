# Simple raffle example, don't use random generation on chain!

# Log statements
TicketBought: event({ticket_number: uint256, participant: address})
WinnerPicked: event({ticket_number: uint256})

# Constants
BLOCKS_PER_ROUND: constant(uint256) = 10
MAX_PARTICIPANTS: constant(uint256) = 200000
SALE_ROUND_LENGTH: constant(uint256) = 5
ROLL_ROUND_LENGTH: constant(uint256) = 10



# lotto_state
# 1: ticket sale
# 2: closed & generate round
# 3: payout
sale_ends: public(uint256)
rolled: public(bool)
winning_number: public(uint256)
participants: public(address[uint256])
participant_count: uint256
charity_address: public(address)


@public
def __init__(_charity_address: address):
    self.charity_address = _charity_address
    self.sale_ends = block.number + SALE_ROUND_LENGTH

@payable
@public
def buy(participant: address, ticket_number: uint256):
    assert participant != ZERO_ADDRESS
    assert msg.value == as_wei_value(0.05, 'ether')
    assert ticket_number <= MAX_PARTICIPANTS
    assert self.participants[ticket_number] == ZERO_ADDRESS
    assert block.number < self.sale_ends
    self.participants[ticket_number] = participant
    self.participant_count += 1
    log.TicketBought(ticket_number, participant)


@private
@constant
def generate_rand() -> uint256:
    hash: bytes32 = sha3(convert(block.number - 1, bytes32))
    return convert(hash, uint256) % self.participant_count


# Roll the dice, and store the winning number.
@public
def roll_dice():
    assert block.number >= self.sale_ends
    self.winning_number = self.generate_rand()
    self.rolled = True
    log.WinnerPicked(self.winning_number)


# if you have the winning ticket cash out.
@public
def payout():
    send(self.participants[self.winning_number], self.balance * 1 / 10)
    selfdestruct(self.charity_address)
