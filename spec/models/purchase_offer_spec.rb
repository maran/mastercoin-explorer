require 'spec_helper'


describe PurchaseOffer do
  context "A valid Purchase Offer" do
    it "should be matched to the last known order if there was no change in this block" do
      FactoryGirl.create(:exodus_transaction)
      old_selling_offer = FactoryGirl.create(:selling_offer)
      purchase_offer = FactoryGirl.create(:purchase_offer, receiving_address: old_selling_offer.address) 

      purchase_offer.selling_offer.should eq(old_selling_offer)
    end

    it "should be matched to a changed order if it can be found in the same block in a lower position" do
      FactoryGirl.create(:exodus_transaction)
      old_selling_offer = FactoryGirl.create(:selling_offer)

      selling_offer = FactoryGirl.create(:selling_offer, block_height: 50, amount_desired: 0.002, position: 4)
      purchase_offer = FactoryGirl.create(:purchase_offer, receiving_address: selling_offer.address, block_height: 50, position: 5) 

      purchase_offer.selling_offer.should eq(selling_offer)
    end

    it "should be matched to the old order if the order has been changed but is on a higher position in the blockchain" do
      FactoryGirl.create(:exodus_transaction)
      old_selling_offer = FactoryGirl.create(:selling_offer)

      selling_offer = FactoryGirl.create(:selling_offer, block_height: 50, amount_desired: 0.002, position: 5)
      purchase_offer = FactoryGirl.create(:purchase_offer, receiving_address: selling_offer.address, block_height: 50, position: 4) 

      purchase_offer.selling_offer.should eq(old_selling_offer)
    end

    it "should adjust the amount available if it's buying more then available" do
      FactoryGirl.create(:exodus_transaction, amount: 5)
      selling_offer = FactoryGirl.create(:selling_offer)
      purchase_offer = FactoryGirl.create(:purchase_offer, receiving_address: selling_offer.address, block_height: 50, position: 4) 
      purchase_offer.accepted_amount.should eq(BigDecimal.new("5"))
    end

    it "should be invalid if the payment came in the same block as the purchase offer but later"
  end
end
