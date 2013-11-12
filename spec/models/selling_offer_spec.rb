require "spec_helper"

describe SellingOffer do
  context "Valid offers" do
    it "should have enough balance to be created" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer)
      selling_offer.check_transaction_validity
      selling_offer.invalid_tx.should eq(false)
    end

    it "should be invalid if there is not enough funds available" do
      selling_offer = FactoryGirl.create(:selling_offer)
      selling_offer.check_transaction_validity
      selling_offer.invalid_tx.should eq(true)
    end

    it "should be valid if it receives a payment in the same block before the offer" do
      selling_offer = FactoryGirl.create(:selling_offer)
      FactoryGirl.create(:receiving_simple_send, block_height: selling_offer.block_height, position: selling_offer.position - 1)
      selling_offer.reload.check_transaction_validity
      selling_offer.reload.invalid_tx.should eq(false)
    end

    it "should be invalid if it receives a payment in the same block after the offer" do
      selling_offer = FactoryGirl.create(:selling_offer)

      simple_send = FactoryGirl.build(:receiving_simple_send)
      simple_send.block_height = selling_offer.block_height
      simple_send.position = selling_offer.position + 1
      simple_send.save

      selling_offer.check_transaction_validity
      selling_offer.invalid_tx.should eq(true)
    end
  end

  context "Current offer" do
    it "should locate the current offer based on a block height and address" do
      FactoryGirl.create(:exodus_transaction)
      FactoryGirl.create(:exodus_transaction)

      selling_offer = FactoryGirl.create(:selling_offer)
      later_selling_offer = FactoryGirl.create(:selling_offer, block_height: selling_offer.block_height + 3)

      SellingOffer.height_and_address((selling_offer.block_height + 1), selling_offer.address).first.should eql(selling_offer)
      SellingOffer.height_and_address((selling_offer.block_height + 2), selling_offer.address).first.should eql(selling_offer)

      SellingOffer.height_and_address((selling_offer.block_height + 4), selling_offer.address).first.should eql(later_selling_offer)
    end
  end

  context "Reserved balance" do
    it "Should reserve the proper amount when creating a selling offer" do
    end

    it "Should invalidate your outgoing transactions if you have a selling offer taking most of your funds" do
    end
  end
end
