require 'test_helper'

class BanTest < ActiveSupport::TestCase
  context "A ban" do
    context "deleting user data" do
      setup do
        @banner = create(:moderator_user)
        CurrentUser.user = @banner
        @bannee = create(:user)
      end

      teardown do
        CurrentUser.user = nil
      end

      should "delete the user's pending posts" do
        @pending_post = create(:post, uploader: @bannee, is_pending: true)
        @active_post = create(:post)
        create(:ban, user: @bannee, banner: @banner, delete_posts: true, post_deletion_reason: "off-topic")

        assert_equal("deleted", @pending_post.reload.status)
        assert_equal("off-topic", @pending_post.flags.last.reason)
        assert_equal("active", @active_post.reload.status)
        assert(ModAction.exists?(category: "post_delete", subject: @pending_post, creator: @banner))
      end

      should "delete the user's comments" do
        @comment = create(:comment, creator: @bannee)

        create(:ban, user: @bannee, banner: @banner, delete_comments: true)
        assert(@comment.reload.is_deleted)
        assert(ModAction.exists?(category: "comment_delete", subject: @comment, creator: @banner))
      end

      should "delete the user's forum posts" do
        @forum_topic = create(:forum_topic, creator: @bannee, original_post: build(:forum_post, creator: @bannee))
        @other_forum_topic = create(:forum_topic, original_post: build(:forum_post))
        @other_forum_post = create(:forum_post, creator: @bannee, topic: @other_forum_topic)
        create(:ban, user: @bannee, banner: @banner, delete_forum_posts: true)

        assert_equal(true, @forum_topic.reload.is_deleted)
        assert_equal(@banner, @forum_topic.updater)

        assert_equal(true, @forum_topic.original_post.is_deleted)
        assert_equal(@banner, @forum_topic.original_post.updater)

        assert_equal(false, @other_forum_topic.is_deleted)
        assert_equal(false, @other_forum_topic.original_post.is_deleted)

        assert_equal(true, @other_forum_post.reload.is_deleted)
        assert_equal(@banner, @other_forum_post.updater)

        assert(ModAction.exists?(category: "forum_topic_delete", subject: @forum_topic, creator: @banner))
        assert(ModAction.exists?(category: "forum_post_delete", subject: @other_forum_post, creator: @banner))
      end

      should "not allow mods to delete votes" do
        @post_vote = create(:post_vote, user: @bannee)
        @ban = build(:ban, user: @bannee, banner: @banner, delete_post_votes: true)

        assert_not(@ban.valid?)
        assert_equal(["Delete post votes is not allowed by Moderator"], @ban.errors.full_messages)
        assert_not(@post_vote.reload.is_deleted)
      end

      should "allow admins to delete votes" do
        @comment_vote = create(:comment_vote, user: @bannee)
        @post_vote = create(:post_vote, user: @bannee)
        @banner = create(:admin_user)

        create(:ban, user: @bannee, banner: @banner, delete_post_votes: true, delete_comment_votes: true)
        assert(@comment_vote.reload.is_deleted)
        assert(@post_vote.reload.is_deleted)
        assert(ModAction.exists?(category: "post_vote_delete", subject: @post_vote, creator: @banner))
        assert(ModAction.exists?(category: "comment_vote_delete", subject: @comment_vote, creator: @banner))
      end

      should "not delete anything unwanted" do
        @post = create(:post, uploader: @bannee, is_pending: true)
        @comment = create(:comment, creator: @bannee)
        @forum_post = create(:forum_post, creator: @bannee)
        @post_vote = create(:post_vote, user: @bannee)
        create(:ban, user: @bannee, banner: @banner)

        assert(@post.reload.status == "pending")
        assert_not(@comment.reload.is_deleted)
        assert_not(@forum_post.reload.is_deleted)
        assert_not(@post_vote.reload.is_deleted)
      end

      should "not delete data more than 3 days old" do
        @comment = create(:comment, creator: @bannee, created_at: 4.days.ago)
        create(:ban, user: @bannee, delete_comments: true)

        assert_not(@comment.reload.is_deleted)
      end
    end

    should "set the is_banned flag on the user" do
      ban = create(:ban)
      assert_equal(true, ban.user.reload.is_banned?)
    end

    should "not allow the user to be banned twice" do
      user = create(:user)
      ban1 = create(:ban, user: user)
      ban2 = build(:ban, user: user)

      assert_equal(false, ban2.save)
      assert_equal(["User is already banned"], ban2.errors.full_messages)
    end

    should "initialize the expiration date" do
      ban = create(:ban)
      assert_not_nil(ban.expires_at)
    end

    should "create a mod action" do
      user = create(:user)
      ban = create(:ban, user: user, duration: 100.years, reason: "lol")

      assert_equal("banned <@#{user.name}> forever: lol", ModAction.last.description)
      assert_equal("user_ban", ModAction.last.category)
      assert_equal(user, ModAction.last.subject)
      assert_equal(ban.banner, ModAction.last.creator)
    end

    should "update the user's feedback" do
      user = create(:user)
      ban = create(:ban, user: user, duration: 100.years, reason: "lol")

      assert_equal(1, user.feedback.negative.count)
      assert_equal("Banned forever: lol", user.feedback.last.body)
    end

    should "send the user a dmail" do
      user = create(:user)
      ban = create(:ban, user: user, duration: 100.years, reason: "lol")

      assert_equal(1, user.dmails.count)
      assert_equal("You have been banned", user.dmails.last.title)
      assert_equal("You have been banned forever: lol", user.dmails.last.body)
    end

    context "Updating a ban" do
      should "unban the user if the ban is reduced" do
        @mod = create(:moderator_user)
        @ban = create(:ban, created_at: 6.months.ago, duration: 1.year)
        assert_equal(true, @ban.user.reload.is_banned?)

        @ban.update!(duration: 1.day, updater: @mod)
        assert_equal(false, @ban.user.reload.is_banned?)

        assert_equal("updated ban duration for <@#{@ban.user.name}>", ModAction.last.description)
        assert_equal("user_ban_update", ModAction.last.category)
        assert_equal(@ban.user, ModAction.last.subject)
        assert_equal(@mod, ModAction.last.creator)
      end

      should "keep the user banned if an active ban is extended" do
        @mod = create(:moderator_user)
        @ban = create(:ban, created_at: 1.month.ago, duration: 3.months)
        assert_equal(true, @ban.user.reload.is_banned?)

        @ban.update!(duration: 1.year, updater: @mod)
        assert_equal(true, @ban.user.reload.is_banned?)

        assert_equal("updated ban duration for <@#{@ban.user.name}>", ModAction.last.description)
        assert_equal("user_ban_update", ModAction.last.category)
        assert_equal(@ban.user, ModAction.last.subject)
        assert_equal(@mod, ModAction.last.creator)
      end

      should "not unban the user if they have another active ban" do
        @user = create(:user)
        @ban1 = create(:ban, user: @user, created_at: 1.week.ago, duration: 1.month)
        @ban2 = build(:ban, user: @user, created_at: 1.week.ago, duration: 3.months).tap { |ban| ban.save!(validate: false) }

        @ban1.update!(duration: 1.day)
        assert_equal(true, @user.reload.is_banned?)

        @ban2.update!(duration: 1.day)
        assert_equal(false, @user.reload.is_banned?)
      end

      should "fail if the ban is expired" do
        @mod = create(:moderator_user)
        @ban = create(:ban, created_at: 6.months.ago, duration: 1.day)

        @ban.update(duration: 1.year, updater: @mod)

        assert_equal("You can't update an expired ban", @ban.errors.full_messages.first)
        assert_equal(1.day, @ban.reload.duration)
      end
    end

    context "Destroying a ban" do
      should "create an unban mod action" do
        @ban = create(:ban)
        @banner = create(:moderator_user)
        assert_equal(true, @ban.user.is_banned?)

        @ban.updater = @banner
        @ban.destroy!

        assert_equal(false, @ban.user.reload.is_banned?)
        assert_match(/unbanned <@#{@ban.user.name}>/, ModAction.last.description)
        assert_equal(@ban.user, ModAction.last.subject)
        assert_equal(@banner, ModAction.last.creator)
      end

      should "not unban the user if they have another active ban" do
        @user = create(:user)
        @ban1 = create(:ban, user: @user, duration: 1.week)
        @ban2 = build(:ban, user: @user, duration: 1.month).tap { |ban| ban.save!(validate: false) }

        @ban1.destroy!
        assert_equal(true, @user.reload.is_banned?)

        @ban2.destroy!
        assert_equal(false, @user.reload.is_banned?)
      end

      should "fail if the ban is expired" do
        @ban = create(:ban, created_at: 6.months.ago, duration: 1.day)
        @banner = create(:moderator_user)

        @ban.updater = @banner
        @ban.destroy

        assert_equal(false, @ban.destroyed?)
        assert_equal("You can't update an expired ban", @ban.errors.full_messages.first)
      end
    end

    context "when validating a ban" do
      subject { build(:ban) }

      should normalize_attribute(:reason).from(" \nfoo\tbar \n").to("foo bar")

      should allow_value(1.day.iso8601).for(:duration)
      should allow_value(3.days.iso8601).for(:duration)
      should allow_value(7.days.iso8601).for(:duration)
      should allow_value(1.month.iso8601).for(:duration)
      should allow_value(3.months.iso8601).for(:duration)
      should allow_value(6.months.iso8601).for(:duration)
      should allow_value(1.year.iso8601).for(:duration)
      should allow_value(100.years.iso8601).for(:duration)
      should_not allow_value(2.days.iso8601).for(:duration)

      should allow_value("x" * 600).for(:reason)
      should_not allow_value("x" * 601).for(:reason)
      should_not allow_value(" ").for(:reason)
    end
  end

  context "Searching for a ban" do
    should "find a given ban" do
      ban = create(:ban)

      assert_search_equals(ban, user_name: ban.user.name, banner_name: ban.banner.name, reason: ban.reason, expired: false, order: :id_desc)
    end
  end
end
