require 'test_helper'

class ValidateAttachmentContentTypeMatcherTest < Test::Unit::TestCase
  context "validate_attachment_content_type" do
    setup do
      reset_table("dummies") do |d|
        d.string :avatar_file_name
      end
      @dummy_class = reset_class "Dummy"
      @dummy_class.has_attached_file :avatar
      @matcher     = self.class.validate_attachment_content_type(:avatar).
                       allowing(%w(image/png image/jpeg)).
                       rejecting(%w(audio/mp3 application/octet-stream))
    end

    should "reject a class with no validation" do
      assert_rejects @matcher, @dummy_class
    end

    should "reject a class with a validation that doesn't match" do
      @dummy_class.validates_attachment_content_type :avatar, :content_type => %r{audio/.*}
      assert_rejects @matcher, @dummy_class
    end

    should "accept a class with a validation" do
      @dummy_class.validates_attachment_content_type :avatar, :content_type => %r{image/.*}
      assert_accepts @matcher, @dummy_class
    end

    should "have messages" do
      assert_equal "validate the content types allowed on attachment avatar", @matcher.description
      assert_equal(
        "Content types image/png, image/jpeg should be accepted and audio/mp3, " \
        "application/octet-stream rejected by avatar",
        @matcher.failure_message
      )
      assert_equal(
        "Content types image/png, image/jpeg should be rejected and audio/mp3, " \
        "application/octet-stream accepted by avatar",
        @matcher.negative_failure_message
      )
    end
  end
end
