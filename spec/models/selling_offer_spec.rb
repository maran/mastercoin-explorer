require "spec_helper"

describe SellingOffer do
  context "Invalid offers" do
    it "should deny real Mastercoin selling offers" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer, currency_id: 1)
      selling_offer.invalid_tx.should eq(true)
    end
  end

  context "Valid offers" do
    it "should have enough balance to be created" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer)
      selling_offer.invalid_tx.should eq(false)
    end

    it "should be invalid if there is not enough funds available" do
      selling_offer = FactoryGirl.create(:selling_offer)
      selling_offer.invalid_tx.should eq(true)
    end

    it "should be valid if it receives a payment in the same block before the offer" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer)
      FactoryGirl.create(:receiving_simple_send, block_height: selling_offer.block_height, position: selling_offer.position - 1)
      selling_offer.invalid_tx.should eq(false)
    end

    it "should be invalid if it receives a payment in the same block after the offer" do
      selling_offer = FactoryGirl.create(:selling_offer)

      simple_send = FactoryGirl.build(:receiving_simple_send)
      simple_send.block_height = selling_offer.block_height
      simple_send.position = selling_offer.position + 1
      simple_send.save

      selling_offer.invalid_tx.should eq(true)
    end

    it "should set the amount per coin" do
      selling_offer = FactoryGirl.create(:selling_offer, amount: 10, amount_desired: 10)
      selling_offer.price_per_coin.should eq(1)
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

    it "Should group offers by address" do 
      FactoryGirl.create(:exodus_transaction)

      selling_offer = FactoryGirl.create(:selling_offer, amount_desired: 1, amount: 1, block_height: 55)
      selling_offer2 = FactoryGirl.create(:selling_offer, amount_desired: 5, amount: 1, block_height: 50)
      selling_offer2.other_offers.collect(&:id).include?(selling_offer.id).should be(true)
    end

    it "Should flag the current offer so we can easily display it on our website" do
      FactoryGirl.create(:exodus_transaction)

      selling_offer = FactoryGirl.build(:selling_offer, amount_desired: 1, amount: 1, block_height: 55)
      selling_offer.save
      SellingOffer.where(address: selling_offer.address).current.should eq(selling_offer)

      selling_offer2 = FactoryGirl.build(:selling_offer, amount_desired: 5, amount: 1, block_height: 50)
      selling_offer2.save
      SellingOffer.where(address: selling_offer.address).current.should eq(selling_offer)

      selling_offer3 = FactoryGirl.create(:selling_offer, amount_desired: 2, amount: 1, block_height: 70)
      SellingOffer.where(address: selling_offer.address).current.should eq(selling_offer3)
    end
  end

  context "Available balance" do
    it "Should calculate available amount based on block height" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer, amount_desired: 1, amount: 1, block_height: 55)
      selling_offer.amount_available.should eq(1)
      offer = FactoryGirl.create(:purchase_offer, status: 2, amount: 0.05, block_height: 57)
      selling_offer.amount_available(offer.app_position).should eq(1)
    end

    it "Should decrease for every Purchase Offer made" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer, amount_desired: 1, amount: 5, block_height: 55)

      offer = FactoryGirl.create(:purchase_offer, status: PurchaseOffer::STATUS_OPEN, requested_amount: 2, block_height: 60, invalid_tx: false)
      offer.invalid_tx.should eq(false)

      selling_offer.amount_available(offer.app_position + 1).to_f.should eq(3)
      offer.update_attributes(status: PurchaseOffer::STATUS_CLOSED) 
      selling_offer.amount_available.to_f.should eq(5)
    end
  end

  context "Reserved balance" do
    it "Should reserve the proper amount when creating a selling offer" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer, amount_desired: 1, amount: 1, block_height: 55)
      Address.create(name: selling_offer.address).reserved_test_balance.should eq(1)
    end

    it "Should only reserve current orders, not expired ones" do
      FactoryGirl.create(:exodus_transaction)
      selling_offer = FactoryGirl.create(:selling_offer, amount_desired: 1, amount: 1, block_height: 55)

      selling_offer = FactoryGirl.create(:selling_offer, amount_desired: 1, amount: 1, block_height: 65)
      address = Address.create(name: selling_offer.address)
      address.reserved_test_balance.should eq(1)
      address.test_balance.should eq(9)
    end

    it "Should invalidate your outgoing transactions if you have a selling offer taking most of your funds" do
    end
  end
end
