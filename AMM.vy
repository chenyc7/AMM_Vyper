from vyper.interfaces import ERC20

tokenAQty: public(uint256) #Quantity of tokenA held by the contract
tokenBQty: public(uint256) #Quantity of tokenB held by the contract

invariant: public(uint256) #The Constant-Function invariant (tokenAQty*tokenBQty = invariant throughout the life of the contract)
tokenA: ERC20 #The ERC20 contract for tokenA
tokenB: ERC20 #The ERC20 contract for tokenB
owner: public(address) #The liquidity provider (the address that has the right to withdraw funds and close the contract)

@external
def get_token_address(token: uint256) -> address:
	if token == 0:
		return self.tokenA.address
	if token == 1:
		return self.tokenB.address
	return ZERO_ADDRESS	

# Sets the on chain market maker with its owner, and initial token quantities
@external
def provideLiquidity(tokenA_addr: address, tokenB_addr: address, tokenA_quantity: uint256, tokenB_quantity: uint256):
	assert self.invariant == 0 #This ensures that liquidity can only be provided once
	#Your code here

	self.tokenA = ERC20(tokenA_addr)
	self.tokenB = ERC20(tokenB_addr)

	self.tokenA.transferFrom(msg.sender, self, tokenA_quantity)
	self.tokenB.transferFrom(msg.sender, self, tokenB_quantity)

	self.owner = msg.sender

	self.tokenAQty = tokenA_quantity
	self.tokenBQty = tokenB_quantity


	self.invariant = tokenA_quantity * tokenB_quantity

	assert self.invariant > 0


# Trades one token for the other
@external
def tradeTokens(sell_token: address, sell_quantity: uint256):
    assert sell_token == self.tokenA.address or sell_token == self.tokenB.address

    new_total_A_tokens : uint256 = self.tokenAQty 
    new_total_B_tokens : uint256 = self.tokenBQty 

    if sell_token == self.tokenA.address:
        self.tokenA.transferFrom(msg.sender, self, sell_quantity)
        new_total_A_tokens = self.tokenAQty + sell_quantity
        new_total_B_tokens = self.invariant / new_total_A_tokens
        self.tokenB.transfer(msg.sender, self.tokenBQty - new_total_B_tokens)

        
    if sell_token == self.tokenB.address:
        self.tokenB.transferFrom(msg.sender, self, sell_quantity)

        new_total_B_tokens = self.tokenBQty + sell_quantity
        new_total_A_tokens = self.invariant / new_total_B_tokens
        self.tokenA.transfer(msg.sender, self.tokenAQty - new_total_A_tokens)


    self.tokenAQty = new_total_A_tokens
    self.tokenBQty = new_total_B_tokens


# Owner can withdraw their funds and destroy the market maker
@external
def ownerWithdraw():
    assert self.owner == msg.sender
    self.tokenA.transfer(self.owner, self.tokenAQty)
    self.tokenB.transfer(self.owner, self.tokenBQty)

    selfdestruct(self.owner)





