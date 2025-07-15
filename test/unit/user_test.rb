require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def assert_promoted_to(new_level, user, promoter)
    user.promote_to!(new_level, promoter)
    assert_equal(new_level, user.reload.level)
  end

  def assert_not_promoted_to(new_level, user, promoter)
    assert_raise(User::PrivilegeError) do
      user.promote_to!(new_level, promoter)
    end

    assert_not_equal(new_level, user.reload.level)
  end

  context "A user" do
    setup do
      @user = FactoryBot.create(:user)
      CurrentUser.user = @user
    end

    teardown do
      CurrentUser.user = nil
    end

    context "promoting a user" do
      setup do
        @builder = create(:builder_user)
        @mod = create(:moderator_user)
        @admin = create(:admin_user)
        @owner = create(:owner_user)
      end

      should "allow moderators to promote users up to approver level" do
        assert_promoted_to(User::Levels::GOLD, @user, @mod)
        assert_promoted_to(User::Levels::PLATINUM, @user, @mod)
        assert_promoted_to(User::Levels::BUILDER, @user, @mod)
        assert_promoted_to(User::Levels::CONTRIBUTOR, @user, @mod)
        assert_promoted_to(User::Levels::APPROVER, @user, @mod)

        assert_not_promoted_to(User::Levels::MODERATOR, @user, @mod)
        assert_not_promoted_to(User::Levels::ADMIN, @user, @mod)
        assert_not_promoted_to(User::Levels::OWNER, @user, @mod)
      end

      should "allow admins to promote users up to moderator level" do
        assert_promoted_to(User::Levels::GOLD, @user, @admin)
        assert_promoted_to(User::Levels::PLATINUM, @user, @admin)
        assert_promoted_to(User::Levels::BUILDER, @user, @admin)
        assert_promoted_to(User::Levels::CONTRIBUTOR, @user, @mod)
        assert_promoted_to(User::Levels::APPROVER, @user, @admin)
        assert_promoted_to(User::Levels::MODERATOR, @user, @admin)

        assert_not_promoted_to(User::Levels::ADMIN, @user, @admin)
        assert_not_promoted_to(User::Levels::OWNER, @user, @admin)
      end

      should "allow the owner to promote users up to admin level" do
        assert_promoted_to(User::Levels::GOLD, @user, @owner)
        assert_promoted_to(User::Levels::PLATINUM, @user, @owner)
        assert_promoted_to(User::Levels::BUILDER, @user, @owner)
        assert_promoted_to(User::Levels::MODERATOR, @user, @owner)
        assert_promoted_to(User::Levels::ADMIN, @user, @owner)

        assert_not_promoted_to(User::Levels::OWNER, @user, @owner)
      end

      should "not allow non-moderators to promote other users" do
        assert_not_promoted_to(User::Levels::GOLD, @user, @builder)
        assert_not_promoted_to(User::Levels::PLATINUM, @user, @builder)
        assert_not_promoted_to(User::Levels::BUILDER, @user, @builder)
        assert_not_promoted_to(User::Levels::MODERATOR, @user, @builder)
        assert_not_promoted_to(User::Levels::ADMIN, @user, @builder)
        assert_not_promoted_to(User::Levels::OWNER, @user, @builder)
      end

      should "not allow users to promote or demote other users at their rank or above" do
        assert_not_promoted_to(User::Levels::ADMIN, create(:moderator_user), @mod)
        assert_not_promoted_to(User::Levels::BUILDER, create(:moderator_user), @mod)

        assert_not_promoted_to(User::Levels::OWNER, create(:admin_user), @admin)
        assert_not_promoted_to(User::Levels::MODERATOR, create(:admin_user), @admin)

        assert_not_promoted_to(User::Levels::ADMIN, create(:owner_user), @owner)
      end

      should "not allow users to promote themselves" do
        assert_not_promoted_to(User::Levels::ADMIN, @mod, @mod)
        assert_not_promoted_to(User::Levels::OWNER, @admin, @admin)
      end

      should "not allow users to demote themselves" do
        assert_not_promoted_to(User::Levels::MEMBER, @mod, @mod)
        assert_not_promoted_to(User::Levels::MEMBER, @admin, @admin)
        assert_not_promoted_to(User::Levels::MEMBER, @owner, @owner)
      end

      should "not allow users to be promoted to an invalid level" do
        assert_not_promoted_to(User::Levels::ANONYMOUS, @user, @mod)
        assert_not_promoted_to(-1, @user, @mod)
        assert_not_promoted_to(1, @user, @mod)
      end

      should "create a neutral feedback" do
        @user.promote_to!(User::Levels::GOLD, @mod)
        assert_equal("You have been promoted to a Gold level account from Member.", @user.feedback.last.body)
      end

      should "send an automated dmail to the user" do
        bot = FactoryBot.create(:user)
        User.stubs(:system).returns(bot)

        assert_difference("Dmail.count", 1) do
          @user.promote_to!(User::Levels::GOLD, @admin)
        end

        assert(@user.dmails.exists?(from: bot, to: @user, title: "Your account has been updated"))
        refute(@user.dmails.exists?(from: bot, to: @user, title: "Your user record has been updated"))
      end

      should "max out the user's upload points when promoting to contributor or higher" do
        assert_equal(UploadLimit::INITIAL_POINTS, @user.upload_points)

        @user.promote_to!(User::Levels::CONTRIBUTOR, @admin)
        assert_equal(UploadLimit::MAXIMUM_POINTS, @user.reload.upload_points)
      end

      should "recalculate the user's upload points when demoting them to below a contributor" do
        assert_equal(UploadLimit::MAXIMUM_POINTS, @mod.upload_points)

        @mod.promote_to!(User::Levels::MEMBER, @admin)
        assert_equal(UploadLimit::INITIAL_POINTS, @mod.reload.upload_points)
      end
    end

    should "authenticate password" do
      assert_equal(@user, @user.authenticate_password("password"))
      assert_equal(false, @user.authenticate_password("password2"))
    end

    should "normalize its level" do
      user = FactoryBot.create(:user, :level => User::Levels::OWNER)
      assert(user.is_owner?)
      assert(user.is_admin?)
      assert(user.is_moderator?)
      assert(user.is_gold?)

      user = FactoryBot.create(:user, :level => User::Levels::ADMIN)
      assert(!user.is_owner?)
      assert(user.is_moderator?)
      assert(user.is_gold?)

      user = FactoryBot.create(:user, :level => User::Levels::MODERATOR)
      assert(!user.is_admin?)
      assert(user.is_moderator?)
      assert(user.is_gold?)

      user = FactoryBot.create(:user, :level => User::Levels::GOLD)
      assert(!user.is_admin?)
      assert(!user.is_moderator?)
      assert(user.is_gold?)

      user = FactoryBot.create(:user)
      assert(!user.is_admin?)
      assert(!user.is_moderator?)
      assert(!user.is_gold?)
    end

    context "name" do
      should "not contain whitespace" do
        # U+2007: https://en.wikipedia.org/wiki/Figure_space
        user = build(:user, name: "foo\u2007bar")
        user.save
        assert_equal(["Name can't contain whitespace"], user.errors.full_messages)
      end

      should "not conflict with an existing name" do
        create(:user, name: "bkub")
        user = build(:user, name: "BKUB")
        user.save
        assert_equal(["Name already taken"], user.errors.full_messages)
      end

      should "be less than 25 characters long" do
        user = build(:user, name: "a"*25)
        user.save
        assert_equal(["Name must be less than 25 characters long"], user.errors.full_messages)
      end

      should "not contain a colon" do
        user = build(:user, name: "a:b")
        user.save
        assert_equal(["Name can't contain ':'"], user.errors.full_messages)
      end

      should "not begin with an underscore" do
        user = build(:user, name: "_x")
        user.save
        assert_equal(["Name can't start with '_'"], user.errors.full_messages)
      end

      should "not end with an underscore" do
        user = build(:user, name: "x_")
        user.save
        assert_equal(["Name can't end with '_'"], user.errors.full_messages)
      end

      should "not contain consecutive underscores" do
        user = build(:user, name: "x__y")
        user.save
        assert_equal(["Name can't contain multiple underscores in a row"], user.errors.full_messages)
      end

      should "not allow non-ASCII characters" do
        user = build(:user, name: "Pokémon")
        user.save
        assert_equal(["Name must contain only basic letters or numbers"], user.errors.full_messages)
      end

      should "not allow names ending in file extensions" do
        user = build(:user, name: "evazion.json")
        user.save
        assert_equal(["Name can't end with a file extension"], user.errors.full_messages)
      end

      should "not be in the same format as a deleted user" do
        user = build(:user, name: "user_1234")
        user.save
        assert_equal(["Name can't be the same as a deleted user"], user.errors.full_messages)
      end

      should "not allow blacklisted names" do
        Danbooru.config.stubs(:user_name_blacklist).returns(["voldemort"])
        user = build(:user, name: "voldemort42")
        user.save
        assert_equal(["Name is not allowed"], user.errors.full_messages)
      end

      should_not allow_value("any").for(:name)
      should_not allow_value("none").for(:name)
      should_not allow_value("new").for(:name)
      should_not allow_value("admin").for(:name)
      should_not allow_value("mod").for(:name)
      should_not allow_value("moderator").for(:name)

      should_not allow_value("foo_\u115F").for(:name)
      should_not allow_value("foo_\u1160").for(:name)
      should_not allow_value("foo_\u3164").for(:name)
      should_not allow_value("foo_\uFFA0").for(:name)
    end

    context "searching for users by name" do
      setup do
        @miku = create(:user, name: "hatsune_miku")
      end

      should "be case-insensitive" do
        assert_equal("hatsune_miku", User.normalize_name("Hatsune_Miku"))
        assert_equal(@miku.id, User.find_by_name("Hatsune_Miku").id)
        assert_equal(@miku.id, User.name_to_id("Hatsune_Miku"))
      end

      should "handle whitespace" do
        assert_equal("hatsune_miku", User.normalize_name(" hatsune miku "))
        assert_equal(@miku.id, User.find_by_name(" hatsune miku ").id)
        assert_equal(@miku.id, User.name_to_id(" hatsune miku "))
      end

      should "return nil for nonexistent names" do
        assert_nil(User.find_by_name("does_not_exist"))
        assert_nil(User.name_to_id("does_not_exist"))
      end

      should "work for names containing asterisks or backslashes" do
        @user1 = build(:user, name: "user*1")
        @user2 = build(:user, name: "user*2")
        @user3 = build(:user, name: "user\*3")

        @user1.save(validate: false)
        @user2.save(validate: false)
        @user3.save(validate: false)

        assert_equal(@user1.id, User.find_by_name("user*1").id)
        assert_equal(@user2.id, User.find_by_name("user*2").id)
        assert_equal(@user3.id, User.find_by_name("user\*3").id)
      end
    end

    context "ip address" do
      setup do
        @user = FactoryBot.create(:user)
      end

      context "in the json representation" do
        should "not appear" do
          assert(@user.to_json !~ /addr/)
        end
      end

      context "in the xml representation" do
        should "not appear" do
          assert(@user.to_xml !~ /addr/)
        end
      end
    end

    context "password" do
      context "in the json representation" do
        setup do
          @user = FactoryBot.create(:user)
        end

        should "not appear" do
          assert(@user.to_json !~ /password/)
        end
      end

      context "in the xml representation" do
        setup do
          @user = FactoryBot.create(:user)
        end

        should "not appear" do
          assert(@user.to_xml !~ /password/)
        end
      end
    end

    context "when searched by name" do
      should "match wildcards" do
        user1 = build(:user, name: "foo")
        user2 = build(:user, name: "foo*bar")
        user3 = build(:user, name: "bar\*baz")

        user1.save(validate: false)
        user2.save(validate: false)
        user3.save(validate: false)

        assert_search_equals([user2, user1], name: "foo*")
        assert_search_equals(user2, name: "foo\*bar")
        assert_search_equals(user3, name: "bar\\\*baz")
      end
    end

    context "custom CSS" do
      should "raise a validation error on invalid custom CSS" do
        user = build(:user, custom_style: "}}}")

        assert_equal(true, user.invalid?)
        assert_match(/contains a syntax error/, user.errors[:custom_style].first)
      end

      should "allow blank CSS" do
        user = build(:user, custom_style: " ")

        assert_equal(true, user.valid?)
      end
    end

    context "during validation" do
      subject { build(:user) }

      context "of level" do
        should allow_value(User::Levels::RESTRICTED).for(:level)
        should allow_value(User::Levels::MEMBER).for(:level)
        should allow_value(User::Levels::GOLD).for(:level)
        should allow_value(User::Levels::PLATINUM).for(:level)
        should allow_value(User::Levels::BUILDER).for(:level)
        should allow_value(User::Levels::CONTRIBUTOR).for(:level)
        should allow_value(User::Levels::APPROVER).for(:level)
        should allow_value(User::Levels::MODERATOR).for(:level)
        should allow_value(User::Levels::ADMIN).for(:level)
        should allow_value(User::Levels::OWNER).for(:level)

        should_not allow_value(User::Levels::ANONYMOUS).for(:level)
        should_not allow_value(-1).for(:level)
        should_not allow_value(1).for(:level)
      end

      context "of blacklisted tags" do
        should normalize_attribute(:blacklisted_tags).from(" foo\n bar \n baz ").to("foo\nbar\nbaz")
        should normalize_attribute(:blacklisted_tags).from(" \t\n ").to("")

        should allow_value("").for(:blacklisted_tags)
        should allow_value("x" * 100_000).for(:blacklisted_tags)
        should allow_value((["x"] * 5_000).join("\n")).for(:blacklisted_tags)
        should allow_value((["x"] * 5_000).join(" ")).for(:blacklisted_tags)

        should_not allow_value("x" * 100_001).for(:blacklisted_tags)
        should_not allow_value((["x"] * 5_001).join("\n")).for(:blacklisted_tags)
        should_not allow_value((["x"] * 5_001).join(" ")).for(:blacklisted_tags)
      end

      context "of favorite tags" do
        should normalize_attribute(:favorite_tags).from(" foo bar ").to("foo bar")
        should normalize_attribute(:favorite_tags).from(" \t\n ").to("")

        should allow_value("").for(:favorite_tags)
        should allow_value("x" * 10_000).for(:favorite_tags)
        should allow_value((["x"] * 1_000).join(" ")).for(:favorite_tags)

        should_not allow_value((["x"] * 1_001).join(" ")).for(:favorite_tags)
        should_not allow_value("x" * 10_001).for(:favorite_tags)
      end

      context "of custom style" do
        should normalize_attribute(:custom_style).from(" foo bar ").to("foo bar")
        should normalize_attribute(:custom_style).from(" \t\n ").to("")

        should allow_value("").for(:custom_style)
        should allow_value("p { color: blue; }").for(:custom_style)
        should allow_value(".#{"x" * 39_900} { color: blue; }").for(:custom_style)

        should_not allow_value(".#{"x" * 40_001} { color: blue; }").for(:custom_style)
      end
    end
  end
end
