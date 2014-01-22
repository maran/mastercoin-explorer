require 'spec_helper'


describe PurchaseOffer do
  context "An invalid offer" do
    it "should be invalid if it can't find a selling offer to match to" do
      purchase_offer = FactoryGirl.create(:purchase_offer)
      purchase_offer.invalid_tx.should be(true)
      purchase_offer.status.should eq(PurchaseOffer::STATUS_OFFER_NOT_FOUND)
    end

    it "Should be invalid if the improper amount of fee paid" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer, required_fee: 0.001)
      purchase_offer = FactoryGirl.create(:purchase_offer, bitcoin_fee: 0.000001)
      purchase_offer.invalid_tx.should eq(true)
      purchase_offer.status.should eq(PurchaseOffer::STATUS_NOT_ENOUGH_FEE)
    end

    it "Should be invalid if the offer was sold out" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer)
      purchase_offer = FactoryGirl.create(:purchase_offer, amount: selling_offer.amount)
      purchase_offer2 = FactoryGirl.create(:purchase_offer, block_height: 10000)
      purchase_offer2.invalid_tx.should eq(true)
      purchase_offer2.status.should eq(PurchaseOffer::STATUS_SOLD_OUT)
    end
  end

  context "A valid offer" do
    it "should be matched to the last known order if there was no change in this block" do
      FactoryGirl.create(:exodus_transaction)
      old_selling_offer = FactoryGirl.create(:selling_offer)
      purchase_offer = FactoryGirl.create(:purchase_offer, receiving_address: old_selling_offer.address) 

      purchase_offer.selling_offer.should eq(old_selling_offer)
    end

    it "should be matched to a changed order if it can be found in the same block in a lower position" do
      FactoryGirl.create(:exodus_transaction)
      old_selling_offer = FactoryGirl.create(:selling_offer, position: 2)

      selling_offer = FactoryGirl.create(:selling_offer, block_height: old_selling_offer.block_height + 1, amount_desired: 0.002)
      purchase_offer = FactoryGirl.create(:purchase_offer, receiving_address: selling_offer.address, block_height: selling_offer.block_height + 1)

      purchase_offer.selling_offer.should eq(selling_offer)
    end

    it "should be matched to the old order if the order has been changed but is on a higher position in the blockchain" do
      FactoryGirl.create(:exodus_transaction)
      old_selling_offer = FactoryGirl.create(:selling_offer, position: 3)

      selling_offer = FactoryGirl.create(:selling_offer, block_height: 50, amount_desired: 0.002, position: 5)
      purchase_offer = FactoryGirl.create(:purchase_offer, receiving_address: selling_offer.address, block_height: 50, position: 4) 

      purchase_offer.selling_offer.should eq(old_selling_offer)
    end

    it "Should calculate the accepted amount for a tranasction" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer, amount_desired: 1, amount: 1, block_height: 55)
      offer = FactoryGirl.create(:purchase_offer, status: PurchaseOffer::STATUS_OPEN, requested_amount: 0.5, block_height: 57)
      offer.accepted_amount.should eq(0.5)
    end

    it "should adjust the amount available if it's buying more then available" do
      FactoryGirl.create(:exodus_transaction, amount: 5)
      selling_offer = FactoryGirl.create(:selling_offer, amount: 5)
      purchase_offer = FactoryGirl.create(:purchase_offer, receiving_address: selling_offer.address, block_height: 50, position: 4, amount: 500) 
      purchase_offer.accepted_amount.should eq(BigDecimal.new("5"))
    end

  end
end
