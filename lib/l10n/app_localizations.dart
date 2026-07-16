import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('ur'),
  ];

  /// No description provided for @enter_title_and_file_warning.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title and choose a file.'**
  String get enter_title_and_file_warning;

  /// No description provided for @asset_uploaded.
  ///
  /// In en, this message translates to:
  /// **'Asset uploaded.'**
  String get asset_uploaded;

  /// No description provided for @upload_btn.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload_btn;

  /// No description provided for @session_rescheduled_title.
  ///
  /// In en, this message translates to:
  /// **'Session Rescheduled'**
  String get session_rescheduled_title;

  /// No description provided for @delete_session_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Session?'**
  String get delete_session_confirm_title;

  /// No description provided for @delete_session_plan_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this session plan?'**
  String get delete_session_plan_confirm;

  /// No description provided for @progress_label.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress_label;

  /// No description provided for @session_word.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session_word;

  /// No description provided for @of_word.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get of_word;

  /// No description provided for @view_details_arrow.
  ///
  /// In en, this message translates to:
  /// **'View Details ›'**
  String get view_details_arrow;

  /// No description provided for @new_member_question.
  ///
  /// In en, this message translates to:
  /// **'New member? '**
  String get new_member_question;

  /// No description provided for @live_label.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live_label;

  /// No description provided for @error_init_app.
  ///
  /// In en, this message translates to:
  /// **'Error initializing app'**
  String get error_init_app;

  /// No description provided for @system_alert.
  ///
  /// In en, this message translates to:
  /// **'System Alert'**
  String get system_alert;

  /// No description provided for @file_uploaded_success.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully ✓'**
  String get file_uploaded_success;

  /// No description provided for @upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get upload_failed;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @paste_link_or_tap.
  ///
  /// In en, this message translates to:
  /// **'Paste a link or tap to upload a doc'**
  String get paste_link_or_tap;

  /// No description provided for @upload_portfolio_doc.
  ///
  /// In en, this message translates to:
  /// **'Upload portfolio doc'**
  String get upload_portfolio_doc;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded ✓'**
  String get uploaded;

  /// No description provided for @mentor_compass.
  ///
  /// In en, this message translates to:
  /// **'Mentor Compass'**
  String get mentor_compass;

  /// No description provided for @career_compass.
  ///
  /// In en, this message translates to:
  /// **'Career Compass'**
  String get career_compass;

  /// No description provided for @learning_roadmap.
  ///
  /// In en, this message translates to:
  /// **'Learning Roadmap'**
  String get learning_roadmap;

  /// No description provided for @failed_generate_roadmap.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate roadmap'**
  String get failed_generate_roadmap;

  /// No description provided for @view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// No description provided for @no_recommended_resources.
  ///
  /// In en, this message translates to:
  /// **'No recommended resources.'**
  String get no_recommended_resources;

  /// No description provided for @no_active_roadmap_found.
  ///
  /// In en, this message translates to:
  /// **'No active roadmap found.'**
  String get no_active_roadmap_found;

  /// No description provided for @suggested_mentors.
  ///
  /// In en, this message translates to:
  /// **'Suggested Mentors'**
  String get suggested_mentors;

  /// No description provided for @recent_mentors.
  ///
  /// In en, this message translates to:
  /// **'Recent Mentors'**
  String get recent_mentors;

  /// No description provided for @all_messages_read.
  ///
  /// In en, this message translates to:
  /// **'All messages marked as read'**
  String get all_messages_read;

  /// No description provided for @error_marking_read.
  ///
  /// In en, this message translates to:
  /// **'Error marking messages as read'**
  String get error_marking_read;

  /// No description provided for @all_chats_cleared.
  ///
  /// In en, this message translates to:
  /// **'All chats cleared successfully'**
  String get all_chats_cleared;

  /// No description provided for @error_clearing_chats.
  ///
  /// In en, this message translates to:
  /// **'Error clearing chats'**
  String get error_clearing_chats;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @search_conversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get search_conversations;

  /// No description provided for @mute_notifications.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get mute_notifications;

  /// No description provided for @mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get mark_all_read;

  /// No description provided for @clear_all_chats.
  ///
  /// In en, this message translates to:
  /// **'Clear all chats'**
  String get clear_all_chats;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @report_user.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get report_user;

  /// No description provided for @start_chatting_with.
  ///
  /// In en, this message translates to:
  /// **'Start Chatting With'**
  String get start_chatting_with;

  /// No description provided for @type_message.
  ///
  /// In en, this message translates to:
  /// **'Type A Message...'**
  String get type_message;

  /// No description provided for @no_meeting_link.
  ///
  /// In en, this message translates to:
  /// **'No meeting link available.'**
  String get no_meeting_link;

  /// No description provided for @invalid_meeting_link.
  ///
  /// In en, this message translates to:
  /// **'Invalid meeting link.'**
  String get invalid_meeting_link;

  /// No description provided for @could_not_open_link.
  ///
  /// In en, this message translates to:
  /// **'Could not open meeting link.'**
  String get could_not_open_link;

  /// No description provided for @session_completed_success.
  ///
  /// In en, this message translates to:
  /// **'Session completed successfully! 🎉'**
  String get session_completed_success;

  /// No description provided for @error_loading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Error loading sessions'**
  String get error_loading_sessions;

  /// No description provided for @search_skills_hint.
  ///
  /// In en, this message translates to:
  /// **'Search skills'**
  String get search_skills_hint;

  /// No description provided for @no_swaps_found.
  ///
  /// In en, this message translates to:
  /// **'No swaps found'**
  String get no_swaps_found;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clear_all;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @edit_skill.
  ///
  /// In en, this message translates to:
  /// **'Edit Skill'**
  String get edit_skill;

  /// No description provided for @update_skill.
  ///
  /// In en, this message translates to:
  /// **'Update Skill'**
  String get update_skill;

  /// No description provided for @profile_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully ✓'**
  String get profile_updated_success;

  /// No description provided for @profile_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile Unavailable'**
  String get profile_unavailable;

  /// No description provided for @could_not_load_profile.
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Profile'**
  String get could_not_load_profile;

  /// No description provided for @no_profile_data.
  ///
  /// In en, this message translates to:
  /// **'No Profile Data Yet'**
  String get no_profile_data;

  /// No description provided for @weekly_activity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weekly_activity;

  /// No description provided for @monthly_activity.
  ///
  /// In en, this message translates to:
  /// **'Monthly Activity'**
  String get monthly_activity;

  /// No description provided for @skill_growth.
  ///
  /// In en, this message translates to:
  /// **'Skill Growth'**
  String get skill_growth;

  /// No description provided for @unlocked_badges.
  ///
  /// In en, this message translates to:
  /// **'Unlocked Badges'**
  String get unlocked_badges;

  /// No description provided for @locked_badges.
  ///
  /// In en, this message translates to:
  /// **'Locked Badges'**
  String get locked_badges;

  /// No description provided for @skills_teaching.
  ///
  /// In en, this message translates to:
  /// **'Skills Teaching'**
  String get skills_teaching;

  /// No description provided for @skills_learned.
  ///
  /// In en, this message translates to:
  /// **'Skills Learned'**
  String get skills_learned;

  /// No description provided for @first_swap.
  ///
  /// In en, this message translates to:
  /// **'First Swap'**
  String get first_swap;

  /// No description provided for @skill_builder.
  ///
  /// In en, this message translates to:
  /// **'Skill Builder'**
  String get skill_builder;

  /// No description provided for @mentor_mode.
  ///
  /// In en, this message translates to:
  /// **'Mentor Mode'**
  String get mentor_mode;

  /// No description provided for @level_5.
  ///
  /// In en, this message translates to:
  /// **'Level 5'**
  String get level_5;

  /// No description provided for @trusted_swapper.
  ///
  /// In en, this message translates to:
  /// **'Trusted Swapper'**
  String get trusted_swapper;

  /// No description provided for @swap_streak.
  ///
  /// In en, this message translates to:
  /// **'Swap Streak'**
  String get swap_streak;

  /// No description provided for @delete_skill.
  ///
  /// In en, this message translates to:
  /// **'Delete Skill'**
  String get delete_skill;

  /// No description provided for @delete_skill_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are You Sure You Want To Permanently Remove This Skill Offer?'**
  String get delete_skill_confirm;

  /// No description provided for @listing_deleted.
  ///
  /// In en, this message translates to:
  /// **'Listing Deleted'**
  String get listing_deleted;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get opening;

  /// No description provided for @could_not_open_document.
  ///
  /// In en, this message translates to:
  /// **'Could not open document'**
  String get could_not_open_document;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @add_assignment.
  ///
  /// In en, this message translates to:
  /// **'Add Assignment'**
  String get add_assignment;

  /// No description provided for @submit_homework.
  ///
  /// In en, this message translates to:
  /// **'Submit Homework'**
  String get submit_homework;

  /// No description provided for @add_feedback_or_file_warning.
  ///
  /// In en, this message translates to:
  /// **'Please add text feedback or upload a file.'**
  String get add_feedback_or_file_warning;

  /// No description provided for @new_assignment_submission.
  ///
  /// In en, this message translates to:
  /// **'New Assignment Submission'**
  String get new_assignment_submission;

  /// No description provided for @homework_submitted_success.
  ///
  /// In en, this message translates to:
  /// **'Homework submitted successfully!'**
  String get homework_submitted_success;

  /// No description provided for @submission_failed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed'**
  String get submission_failed;

  /// No description provided for @submit_assignment.
  ///
  /// In en, this message translates to:
  /// **'Submit Assignment'**
  String get submit_assignment;

  /// No description provided for @enter_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your message here...'**
  String get enter_message_hint;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @enter_grade_warning.
  ///
  /// In en, this message translates to:
  /// **'Please enter a grade.'**
  String get enter_grade_warning;

  /// No description provided for @assignment_graded.
  ///
  /// In en, this message translates to:
  /// **'Assignment Graded!'**
  String get assignment_graded;

  /// No description provided for @submission_graded_success.
  ///
  /// In en, this message translates to:
  /// **'Submission graded successfully!'**
  String get submission_graded_success;

  /// No description provided for @grading_failed.
  ///
  /// In en, this message translates to:
  /// **'Grading failed'**
  String get grading_failed;

  /// No description provided for @review_homework.
  ///
  /// In en, this message translates to:
  /// **'Review Homework Submission'**
  String get review_homework;

  /// No description provided for @submitted_by.
  ///
  /// In en, this message translates to:
  /// **'Submitted By'**
  String get submitted_by;

  /// No description provided for @written_answer.
  ///
  /// In en, this message translates to:
  /// **'Written Answer:'**
  String get written_answer;

  /// No description provided for @attached_file.
  ///
  /// In en, this message translates to:
  /// **'Attached File:'**
  String get attached_file;

  /// No description provided for @feedback_comments.
  ///
  /// In en, this message translates to:
  /// **'Feedback Comments'**
  String get feedback_comments;

  /// No description provided for @submit_grade.
  ///
  /// In en, this message translates to:
  /// **'Submit Grade'**
  String get submit_grade;

  /// No description provided for @downloading_certificate.
  ///
  /// In en, this message translates to:
  /// **'Downloading certificate...'**
  String get downloading_certificate;

  /// No description provided for @sharing_certificate.
  ///
  /// In en, this message translates to:
  /// **'Sharing certificate...'**
  String get sharing_certificate;

  /// No description provided for @swap_completed_success.
  ///
  /// In en, this message translates to:
  /// **'Swap completed successfully!'**
  String get swap_completed_success;

  /// No description provided for @swap_details_not_found.
  ///
  /// In en, this message translates to:
  /// **'Swap details not found.'**
  String get swap_details_not_found;

  /// No description provided for @all_lessons_for.
  ///
  /// In en, this message translates to:
  /// **'All planned lessons for'**
  String get all_lessons_for;

  /// No description provided for @learned_what_promised.
  ///
  /// In en, this message translates to:
  /// **'I have successfully learned what was promised.'**
  String get learned_what_promised;

  /// No description provided for @agree_to_finalize.
  ///
  /// In en, this message translates to:
  /// **'I agree to finalize this exchange.'**
  String get agree_to_finalize;

  /// No description provided for @request_already_exists.
  ///
  /// In en, this message translates to:
  /// **'A request already exists between you and'**
  String get request_already_exists;

  /// No description provided for @add_material.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get add_material;

  /// No description provided for @document_title.
  ///
  /// In en, this message translates to:
  /// **'Document Title'**
  String get document_title;

  /// No description provided for @document_name.
  ///
  /// In en, this message translates to:
  /// **'Document Name'**
  String get document_name;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @new_assignment_assigned.
  ///
  /// In en, this message translates to:
  /// **'New Assignment Assigned'**
  String get new_assignment_assigned;

  /// No description provided for @assignment_created_notification.
  ///
  /// In en, this message translates to:
  /// **'Assignment created and notification sent.'**
  String get assignment_created_notification;

  /// No description provided for @new_session_invitation.
  ///
  /// In en, this message translates to:
  /// **'New Session Invitation'**
  String get new_session_invitation;

  /// No description provided for @session_updated_rescheduled.
  ///
  /// In en, this message translates to:
  /// **'Session updated and rescheduled.'**
  String get session_updated_rescheduled;

  /// No description provided for @session_deleted_success.
  ///
  /// In en, this message translates to:
  /// **'Session deleted successfully.'**
  String get session_deleted_success;

  /// No description provided for @weekly_engagement.
  ///
  /// In en, this message translates to:
  /// **'Weekly Engagement'**
  String get weekly_engagement;

  /// No description provided for @total_skills_learning.
  ///
  /// In en, this message translates to:
  /// **'Total Skills Learning'**
  String get total_skills_learning;

  /// No description provided for @total_skills_teaching.
  ///
  /// In en, this message translates to:
  /// **'Total Skills Teaching'**
  String get total_skills_teaching;

  /// No description provided for @no_teaching_swaps.
  ///
  /// In en, this message translates to:
  /// **'No teaching swaps found.'**
  String get no_teaching_swaps;

  /// No description provided for @thank_you_feedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thank_you_feedback;

  /// No description provided for @feedback_submit_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit feedback'**
  String get feedback_submit_failed;

  /// No description provided for @feedback_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe your learning experience, what you liked, and how they helped you...'**
  String get feedback_hint;

  /// No description provided for @no_meeting_link_provided.
  ///
  /// In en, this message translates to:
  /// **'No meeting link provided for this session.'**
  String get no_meeting_link_provided;

  /// No description provided for @no_sessions_planned.
  ///
  /// In en, this message translates to:
  /// **'No sessions planned yet.'**
  String get no_sessions_planned;

  /// No description provided for @mark_completed.
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get mark_completed;

  /// No description provided for @session_marked_completed.
  ///
  /// In en, this message translates to:
  /// **'Session marked completed.'**
  String get session_marked_completed;

  /// No description provided for @delete_session.
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get delete_session;

  /// No description provided for @delete_session_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this session? This action cannot be undone.'**
  String get delete_session_confirm;

  /// No description provided for @leave_review.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get leave_review;

  /// No description provided for @mark_teaching_complete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Mark Teaching Complete?'**
  String get mark_teaching_complete_confirm;

  /// No description provided for @completion_request_sent.
  ///
  /// In en, this message translates to:
  /// **'Completion request sent successfully!'**
  String get completion_request_sent;

  /// No description provided for @request_more_sessions_confirm.
  ///
  /// In en, this message translates to:
  /// **'Request More Sessions?'**
  String get request_more_sessions_confirm;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @more_sessions_requested_title.
  ///
  /// In en, this message translates to:
  /// **'More Sessions Requested'**
  String get more_sessions_requested_title;

  /// No description provided for @request_sent_mentor.
  ///
  /// In en, this message translates to:
  /// **'Request sent to your mentor.'**
  String get request_sent_mentor;

  /// No description provided for @report_submitted_success.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully. Our team will review it within 24 hours.'**
  String get report_submitted_success;

  /// No description provided for @report_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report'**
  String get report_failed;

  /// No description provided for @report_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened...'**
  String get report_hint;

  /// No description provided for @upcoming_session_title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Skill Swap Session'**
  String get upcoming_session_title;

  /// No description provided for @session_starting_soon.
  ///
  /// In en, this message translates to:
  /// **'Session Starting Soon'**
  String get session_starting_soon;

  /// No description provided for @swap_completion_requested_title.
  ///
  /// In en, this message translates to:
  /// **'Swap Completion Requested'**
  String get swap_completion_requested_title;

  /// No description provided for @swap_completed_title.
  ///
  /// In en, this message translates to:
  /// **'Swap Completed!'**
  String get swap_completed_title;

  /// No description provided for @new_swap_request_title.
  ///
  /// In en, this message translates to:
  /// **'New Swap Request'**
  String get new_swap_request_title;

  /// No description provided for @performance_insights.
  ///
  /// In en, this message translates to:
  /// **'Performance Insights'**
  String get performance_insights;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SkillSwapX'**
  String get appTitle;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profile_info.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profile_info;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @privacy_security.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacy_security;

  /// No description provided for @app_preferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get app_preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @help_center.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get help_center;

  /// No description provided for @about_skill_swap.
  ///
  /// In en, this message translates to:
  /// **'About Skill Swap'**
  String get about_skill_swap;

  /// No description provided for @log_out.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get log_out;

  /// No description provided for @search_language.
  ///
  /// In en, this message translates to:
  /// **'Search Language...'**
  String get search_language;

  /// No description provided for @no_language_found.
  ///
  /// In en, this message translates to:
  /// **'No Language Found'**
  String get no_language_found;

  /// No description provided for @search_another_language.
  ///
  /// In en, this message translates to:
  /// **'Try Searching For Another Language'**
  String get search_another_language;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @swaps.
  ///
  /// In en, this message translates to:
  /// **'Swaps'**
  String get swaps;

  /// No description provided for @good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get good_morning;

  /// No description provided for @good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get good_afternoon;

  /// No description provided for @good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get good_evening;

  /// No description provided for @keep_growing.
  ///
  /// In en, this message translates to:
  /// **'Keep Growing Every Day!'**
  String get keep_growing;

  /// No description provided for @search_skills.
  ///
  /// In en, this message translates to:
  /// **'Search Skills Or Topic...'**
  String get search_skills;

  /// No description provided for @featured_swaps.
  ///
  /// In en, this message translates to:
  /// **'Featured Swaps'**
  String get featured_swaps;

  /// No description provided for @active_swaps.
  ///
  /// In en, this message translates to:
  /// **'Active Swap Sessions'**
  String get active_swaps;

  /// No description provided for @no_listings_found.
  ///
  /// In en, this message translates to:
  /// **'No Listings Found'**
  String get no_listings_found;

  /// No description provided for @adjust_filters.
  ///
  /// In en, this message translates to:
  /// **'Try Adjusting Your Filters Or Be The First To Start A New Swap!'**
  String get adjust_filters;

  /// No description provided for @add_listing.
  ///
  /// In en, this message translates to:
  /// **'Add A Listing'**
  String get add_listing;

  /// No description provided for @nothing_live.
  ///
  /// In en, this message translates to:
  /// **'Nothing Live Yet'**
  String get nothing_live;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi!'**
  String get hi;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome\\nBack!'**
  String get welcome_back;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @new_member.
  ///
  /// In en, this message translates to:
  /// **'New Member? '**
  String get new_member;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get sign_up;

  /// No description provided for @allow_push.
  ///
  /// In en, this message translates to:
  /// **'Allow Push Notifications'**
  String get allow_push;

  /// No description provided for @allow_push_desc.
  ///
  /// In en, this message translates to:
  /// **'Enable Or Disable All Notifications From Skill Swap'**
  String get allow_push_desc;

  /// No description provided for @master_controls.
  ///
  /// In en, this message translates to:
  /// **'Master Controls'**
  String get master_controls;

  /// No description provided for @notification_types.
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notification_types;

  /// No description provided for @swap_proposals.
  ///
  /// In en, this message translates to:
  /// **'Swap Proposals'**
  String get swap_proposals;

  /// No description provided for @swap_proposals_desc.
  ///
  /// In en, this message translates to:
  /// **'Get Notified When Someone Proposes Or Accepts A Skill Swap'**
  String get swap_proposals_desc;

  /// No description provided for @direct_messages.
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get direct_messages;

  /// No description provided for @direct_messages_desc.
  ///
  /// In en, this message translates to:
  /// **'Get Instantly Notified When You Receive A Message In Chats'**
  String get direct_messages_desc;

  /// No description provided for @weekly_tips.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress & Tips'**
  String get weekly_tips;

  /// No description provided for @weekly_tips_desc.
  ///
  /// In en, this message translates to:
  /// **'Tips To Grow Your Skills And Learning Stats'**
  String get weekly_tips_desc;

  /// No description provided for @customize_alerts.
  ///
  /// In en, this message translates to:
  /// **'Customize Your Alerts So You Never Miss A Swap Proposal Or Message From Your Learning Partners.'**
  String get customize_alerts;

  /// No description provided for @welcome_to_skillswap.
  ///
  /// In en, this message translates to:
  /// **'Welcome To SkillSwapX'**
  String get welcome_to_skillswap;

  /// No description provided for @onboard_slogan.
  ///
  /// In en, this message translates to:
  /// **'Trade Skills, Learn Cool Stuff, No Money Needed'**
  String get onboard_slogan;

  /// No description provided for @you_are_offline.
  ///
  /// In en, this message translates to:
  /// **'You Are Offline'**
  String get you_are_offline;

  /// No description provided for @no_internet_line1.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection Found. Check'**
  String get no_internet_line1;

  /// No description provided for @no_internet_line2.
  ///
  /// In en, this message translates to:
  /// **'Your Connection Or Try Again.'**
  String get no_internet_line2;

  /// No description provided for @create_account_here.
  ///
  /// In en, this message translates to:
  /// **'Create An Account Here'**
  String get create_account_here;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @mail.
  ///
  /// In en, this message translates to:
  /// **'Mail'**
  String get mail;

  /// No description provided for @passwords.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwords;

  /// No description provided for @already_member.
  ///
  /// In en, this message translates to:
  /// **'Already A Member? '**
  String get already_member;

  /// No description provided for @account_created.
  ///
  /// In en, this message translates to:
  /// **'Account Created Successfully'**
  String get account_created;

  /// No description provided for @choose_teach_skills.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 skills\\nyou can teach others.'**
  String get choose_teach_skills;

  /// No description provided for @choose_learn_skills.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 skills\\nyou want to learn.'**
  String get choose_learn_skills;

  /// No description provided for @what_can_teach_others.
  ///
  /// In en, this message translates to:
  /// **'What Can You Teach\\nOthers?'**
  String get what_can_teach_others;

  /// No description provided for @what_want_learn.
  ///
  /// In en, this message translates to:
  /// **'What Do You Want\\nTo Learn?'**
  String get what_want_learn;

  /// No description provided for @skill_name.
  ///
  /// In en, this message translates to:
  /// **'Skill Name'**
  String get skill_name;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @my_swaps.
  ///
  /// In en, this message translates to:
  /// **'My Swaps'**
  String get my_swaps;

  /// No description provided for @my_learning.
  ///
  /// In en, this message translates to:
  /// **'My Learning'**
  String get my_learning;

  /// No description provided for @my_teaching.
  ///
  /// In en, this message translates to:
  /// **'My Teaching'**
  String get my_teaching;

  /// No description provided for @swap_more.
  ///
  /// In en, this message translates to:
  /// **'Swap More'**
  String get swap_more;

  /// No description provided for @no_active_swaps.
  ///
  /// In en, this message translates to:
  /// **'No Active Swaps Yet'**
  String get no_active_swaps;

  /// No description provided for @start_journey.
  ///
  /// In en, this message translates to:
  /// **'Start Your Journey Of Knowledge Exchange By Finding A Mentor Or Offering Your Skills.'**
  String get start_journey;

  /// No description provided for @explore_now.
  ///
  /// In en, this message translates to:
  /// **'Explore Now!'**
  String get explore_now;

  /// No description provided for @please_login.
  ///
  /// In en, this message translates to:
  /// **'Please Login'**
  String get please_login;

  /// No description provided for @all_caught_up.
  ///
  /// In en, this message translates to:
  /// **'All Caught Up!'**
  String get all_caught_up;

  /// No description provided for @notifications_will_show.
  ///
  /// In en, this message translates to:
  /// **'When You Get Notifications, They\'ll Show Up Here.'**
  String get notifications_will_show;

  /// No description provided for @about_skill_swap_title.
  ///
  /// In en, this message translates to:
  /// **'About Skill Swap'**
  String get about_skill_swap_title;

  /// No description provided for @legal_agreements.
  ///
  /// In en, this message translates to:
  /// **'Legal & Agreements'**
  String get legal_agreements;

  /// No description provided for @terms_of_service.
  ///
  /// In en, this message translates to:
  /// **'Terms Of Service'**
  String get terms_of_service;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @open_source_licenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get open_source_licenses;

  /// No description provided for @democratizing_education.
  ///
  /// In en, this message translates to:
  /// **'Democratizing Education'**
  String get democratizing_education;

  /// No description provided for @help_center_title.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get help_center_title;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqs;

  /// No description provided for @contact_support.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contact_support;

  /// No description provided for @frequently_asked.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequently_asked;

  /// No description provided for @search_questions.
  ///
  /// In en, this message translates to:
  /// **'Search Questions Or Keywords...'**
  String get search_questions;

  /// No description provided for @submit_ticket.
  ///
  /// In en, this message translates to:
  /// **'Submit A Support Ticket'**
  String get submit_ticket;

  /// No description provided for @help_desk_reply.
  ///
  /// In en, this message translates to:
  /// **'Our Help Desk Team Will Review And Reply Within 12-24 Hours.'**
  String get help_desk_reply;

  /// No description provided for @issue_category.
  ///
  /// In en, this message translates to:
  /// **'Issue Category'**
  String get issue_category;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @message_description.
  ///
  /// In en, this message translates to:
  /// **'Message Description'**
  String get message_description;

  /// No description provided for @submit_support_ticket.
  ///
  /// In en, this message translates to:
  /// **'Submit Support Ticket'**
  String get submit_support_ticket;

  /// No description provided for @ticket_submitted.
  ///
  /// In en, this message translates to:
  /// **'Ticket Submitted!'**
  String get ticket_submitted;

  /// No description provided for @return_to_settings.
  ///
  /// In en, this message translates to:
  /// **'Return To Settings'**
  String get return_to_settings;

  /// No description provided for @privacy_security_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacy_security_title;

  /// No description provided for @profile_visibility.
  ///
  /// In en, this message translates to:
  /// **'Profile Visibility'**
  String get profile_visibility;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @danger_zone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get danger_zone;

  /// No description provided for @visibility_public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visibility_public;

  /// No description provided for @visibility_public_desc.
  ///
  /// In en, this message translates to:
  /// **'Anyone On Skill Swap Can View Your Offered Skills And Portfolio.'**
  String get visibility_public_desc;

  /// No description provided for @visibility_swappers.
  ///
  /// In en, this message translates to:
  /// **'Swappers Only'**
  String get visibility_swappers;

  /// No description provided for @visibility_swappers_desc.
  ///
  /// In en, this message translates to:
  /// **'Only Users With Whom You Have Active Or Completed Swaps Can View Details.'**
  String get visibility_swappers_desc;

  /// No description provided for @visibility_private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get visibility_private;

  /// No description provided for @visibility_private_desc.
  ///
  /// In en, this message translates to:
  /// **'Your Profile And Listings Are Hidden From Search And Browse Lists.'**
  String get visibility_private_desc;

  /// No description provided for @show_online_status.
  ///
  /// In en, this message translates to:
  /// **'Show Online Status'**
  String get show_online_status;

  /// No description provided for @show_online_status_desc.
  ///
  /// In en, this message translates to:
  /// **'Allow Other Users To See When You Are Active'**
  String get show_online_status_desc;

  /// No description provided for @direct_msg_from_anyone.
  ///
  /// In en, this message translates to:
  /// **'Direct Messages From Anyone'**
  String get direct_msg_from_anyone;

  /// No description provided for @direct_msg_from_anyone_desc.
  ///
  /// In en, this message translates to:
  /// **'Allow Users To Send You Messages Without A Swap Request'**
  String get direct_msg_from_anyone_desc;

  /// No description provided for @high_risk_actions.
  ///
  /// In en, this message translates to:
  /// **'High Risk Actions'**
  String get high_risk_actions;

  /// No description provided for @clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear App Cache'**
  String get clear_cache;

  /// No description provided for @clear_cache_desc.
  ///
  /// In en, this message translates to:
  /// **'Free Up Space By Deleting Temporary Cached Files'**
  String get clear_cache_desc;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get delete_account;

  /// No description provided for @delete_account_desc.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Your Profile And All Swap Data'**
  String get delete_account_desc;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clear_cache_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are You Sure You Want To Clear Temporary Files And Cache? This Won\'t Delete Your Profile Details.'**
  String get clear_cache_confirm;

  /// No description provided for @delete_account_confirm.
  ///
  /// In en, this message translates to:
  /// **'WARNING: This Is A Permanent Action! You Will Lose All Your Listings, Chat Histories, Active Swap Connections, And Settings Forever.'**
  String get delete_account_confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear_now.
  ///
  /// In en, this message translates to:
  /// **'Clear Now'**
  String get clear_now;

  /// No description provided for @delete_permanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get delete_permanently;

  /// No description provided for @cache_cleared.
  ///
  /// In en, this message translates to:
  /// **'App Cache Cleared Successfully!'**
  String get cache_cleared;

  /// No description provided for @forgot_password_title.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password_title;

  /// No description provided for @enter_email_otp.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Registered Email Address.\\nWe Will Send A 6-Digit OTP To Verify Your Identity.'**
  String get enter_email_otp;

  /// No description provided for @enter_your_email.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Email'**
  String get enter_your_email;

  /// No description provided for @send_otp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get send_otp;

  /// No description provided for @verify_otp_title.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verify_otp_title;

  /// No description provided for @enter_otp_sent.
  ///
  /// In en, this message translates to:
  /// **'Enter The 6-Digit OTP Sent To'**
  String get enter_otp_sent;

  /// No description provided for @show_otp.
  ///
  /// In en, this message translates to:
  /// **'Show OTP'**
  String get show_otp;

  /// No description provided for @hide_otp.
  ///
  /// In en, this message translates to:
  /// **'Hide OTP'**
  String get hide_otp;

  /// No description provided for @verify_otp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verify_otp;

  /// No description provided for @didnt_receive_otp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t Receive OTP?  '**
  String get didnt_receive_otp;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @offer_new_skill.
  ///
  /// In en, this message translates to:
  /// **'Offer New Skill'**
  String get offer_new_skill;

  /// No description provided for @title_label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title_label;

  /// No description provided for @category_label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category_label;

  /// No description provided for @experience_level.
  ///
  /// In en, this message translates to:
  /// **'Experience Level'**
  String get experience_level;

  /// No description provided for @looking_for.
  ///
  /// In en, this message translates to:
  /// **'I\'m Looking For'**
  String get looking_for;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @description_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description_label;

  /// No description provided for @add_skill.
  ///
  /// In en, this message translates to:
  /// **'Add Skill'**
  String get add_skill;

  /// No description provided for @no_sessions_yet.
  ///
  /// In en, this message translates to:
  /// **'No Sessions Yet.'**
  String get no_sessions_yet;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @add_session.
  ///
  /// In en, this message translates to:
  /// **'Add Session'**
  String get add_session;

  /// No description provided for @overall_progress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overall_progress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @mentor.
  ///
  /// In en, this message translates to:
  /// **'Mentor'**
  String get mentor;

  /// No description provided for @learner.
  ///
  /// In en, this message translates to:
  /// **'Learner'**
  String get learner;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @session_details.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get session_details;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @enter_meeting_room.
  ///
  /// In en, this message translates to:
  /// **'Enter Meeting Room'**
  String get enter_meeting_room;

  /// No description provided for @go_back.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get go_back;

  /// No description provided for @create_session.
  ///
  /// In en, this message translates to:
  /// **'Create Session'**
  String get create_session;

  /// No description provided for @session_title.
  ///
  /// In en, this message translates to:
  /// **'Session Title'**
  String get session_title;

  /// No description provided for @session_title_hint.
  ///
  /// In en, this message translates to:
  /// **'What will this session cover?'**
  String get session_title_hint;

  /// No description provided for @duration_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 hour'**
  String get duration_hint;

  /// No description provided for @meeting_link.
  ///
  /// In en, this message translates to:
  /// **'Meeting Link'**
  String get meeting_link;

  /// No description provided for @meeting_link_hint.
  ///
  /// In en, this message translates to:
  /// **'Zoom, Google Meet, Teams, or other URL'**
  String get meeting_link_hint;

  /// No description provided for @date_and_time.
  ///
  /// In en, this message translates to:
  /// **'Date and Time'**
  String get date_and_time;

  /// No description provided for @session_agenda.
  ///
  /// In en, this message translates to:
  /// **'Session Agenda'**
  String get session_agenda;

  /// No description provided for @session_agenda_hint.
  ///
  /// In en, this message translates to:
  /// **'What would you like to focus on...'**
  String get session_agenda_hint;

  /// No description provided for @required_field.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get required_field;

  /// No description provided for @send_invitation.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get send_invitation;

  /// No description provided for @session_invite_sent.
  ///
  /// In en, this message translates to:
  /// **'Session Invite Sent'**
  String get session_invite_sent;

  /// No description provided for @cannot_swap_with_yourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot swap with yourself!'**
  String get cannot_swap_with_yourself;

  /// No description provided for @confirm_swap.
  ///
  /// In en, this message translates to:
  /// **'Confirm Swap'**
  String get confirm_swap;

  /// No description provided for @swap_request_sent.
  ///
  /// In en, this message translates to:
  /// **'Swap request sent to'**
  String get swap_request_sent;

  /// No description provided for @swap_with_person.
  ///
  /// In en, this message translates to:
  /// **'Swap with this person?'**
  String get swap_with_person;

  /// No description provided for @review_details.
  ///
  /// In en, this message translates to:
  /// **'Review the details before sending your swap request.'**
  String get review_details;

  /// No description provided for @swaps_count.
  ///
  /// In en, this message translates to:
  /// **'swaps'**
  String get swaps_count;

  /// No description provided for @they_offer.
  ///
  /// In en, this message translates to:
  /// **'They Offer'**
  String get they_offer;

  /// No description provided for @they_want.
  ///
  /// In en, this message translates to:
  /// **'They Want'**
  String get they_want;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get something_went_wrong;

  /// No description provided for @clear_all_notifications.
  ///
  /// In en, this message translates to:
  /// **'Clear All Notifications?'**
  String get clear_all_notifications;

  /// No description provided for @clear_all_notifications_desc.
  ///
  /// In en, this message translates to:
  /// **'This Will Permanently Delete Your Notification History.'**
  String get clear_all_notifications_desc;

  /// No description provided for @check_back_later.
  ///
  /// In en, this message translates to:
  /// **'Check Back Later For Updates.'**
  String get check_back_later;

  /// No description provided for @no_notifications.
  ///
  /// In en, this message translates to:
  /// **'No Notifications Here'**
  String get no_notifications;

  /// No description provided for @confirm_completion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Completion'**
  String get confirm_completion;

  /// No description provided for @review_completion_request.
  ///
  /// In en, this message translates to:
  /// **'Review Completion Request'**
  String get review_completion_request;

  /// No description provided for @progress_summary.
  ///
  /// In en, this message translates to:
  /// **'Progress Summary'**
  String get progress_summary;

  /// No description provided for @completed_sessions.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed_sessions;

  /// No description provided for @total_sessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get total_sessions;

  /// No description provided for @mark_as_complete.
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get mark_as_complete;

  /// No description provided for @not_yet.
  ///
  /// In en, this message translates to:
  /// **'Not Yet'**
  String get not_yet;

  /// No description provided for @swap_already_completed.
  ///
  /// In en, this message translates to:
  /// **'Swap Already Completed'**
  String get swap_already_completed;

  /// No description provided for @back_to_home.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get back_to_home;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @certificate_of_completion.
  ///
  /// In en, this message translates to:
  /// **'CERTIFICATE OF COMPLETION'**
  String get certificate_of_completion;

  /// No description provided for @this_is_to_certify.
  ///
  /// In en, this message translates to:
  /// **'This is to certify that'**
  String get this_is_to_certify;

  /// No description provided for @has_successfully_completed_swap.
  ///
  /// In en, this message translates to:
  /// **'has successfully completed the skill swap for'**
  String get has_successfully_completed_swap;

  /// No description provided for @taught_by.
  ///
  /// In en, this message translates to:
  /// **'Taught by'**
  String get taught_by;

  /// No description provided for @authorized.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get authorized;

  /// No description provided for @leave_feedback.
  ///
  /// In en, this message translates to:
  /// **'Leave Feedback'**
  String get leave_feedback;

  /// No description provided for @submit_feedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submit_feedback;

  /// No description provided for @maybe_later.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybe_later;

  /// No description provided for @general_inquiry.
  ///
  /// In en, this message translates to:
  /// **'General Inquiry'**
  String get general_inquiry;

  /// No description provided for @technical_issue.
  ///
  /// In en, this message translates to:
  /// **'Technical Issue'**
  String get technical_issue;

  /// No description provided for @swap_dispute.
  ///
  /// In en, this message translates to:
  /// **'Swap Dispute'**
  String get swap_dispute;

  /// No description provided for @account_security.
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get account_security;

  /// No description provided for @feedback_suggestion.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Suggestion'**
  String get feedback_suggestion;

  /// No description provided for @subject_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chat is not loading'**
  String get subject_hint;

  /// No description provided for @subject_required.
  ///
  /// In en, this message translates to:
  /// **'Subject is required'**
  String get subject_required;

  /// No description provided for @message_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue in detail...'**
  String get message_hint;

  /// No description provided for @message_required.
  ///
  /// In en, this message translates to:
  /// **'Please describe your query'**
  String get message_required;

  /// No description provided for @ticket_success_msg.
  ///
  /// In en, this message translates to:
  /// **'Your support ticket has been submitted successfully.\\n\\nOur team will contact you at your registered email address shortly.'**
  String get ticket_success_msg;

  /// No description provided for @mission_statement.
  ///
  /// In en, this message translates to:
  /// **'Skill Swap is an innovative peer-to-peer knowledge barter platform designed to bring learners and mentors together. We believe that everyone is an expert in something and a student in another.\\n\\nOur mission is to bypass financial barriers in career growth, hobbies, and educational pursuits by establishing a direct value exchange—helping you teach what you love to learn what you need.'**
  String get mission_statement;

  /// No description provided for @terms_of_service_content.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Skill Swap! These Terms of Service ('**
  String get terms_of_service_content;

  /// No description provided for @privacy_policy_content.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is extremely important to us. This Privacy Policy describes how Skill Swap collects, protects, and handles your information.\\n\\n1. INFORMATION WE COLLECT\\n- Account Data: Name, email address, password, profile photo, and biography.\\n- Skills Listing Data: Details of the skills you offer and want.\\n- Chat Data: Chat messages and connection requests to coordinate swaps.\\n- App Usage Data: Analytics regarding popular categories.\\n\\n2. HOW WE USE YOUR INFORMATION\\n- To facilitate connections and exchange messaging between swapping partners.\\n- To personalize your home screen matching feeds.\\n- To secure and authenticate your account through Firebase Auth.\\n\\n3. DATA RETENTION\\nWe store your profile data on Google Firebase and Supabase for as long as your account remains active. You can trigger mock account deletion or contact support to request permanent deletion at any time.\\n\\n4. THIRD-PARTY SERVICES\\nWe utilize third-party SDKs including Google Firebase (Authentication, Storage, Firestore) and Supabase to host listings and perform platform analytics. These services operate under their respective privacy policies.\\n\\n5. SECURITY\\nWe apply industry-standard cloud protection policies to protect your data. However, no database transmission is 100% secure. Please choose strong, unique credentials.'**
  String get privacy_policy_content;

  /// No description provided for @open_source_licenses_content.
  ///
  /// In en, this message translates to:
  /// **'Skill Swap is made possible by the incredible open-source community! Below are primary frameworks and libraries used:\\n\\n■ Flutter SDK\\nCopyright 2014 The Flutter Authors. All rights reserved.\\nLicensed under the BSD 3-Clause License.\\n\\n■ Firebase Core & Auth\\nCopyright 2020 Google LLC. All rights reserved.\\nLicensed under the Apache License, Version 2.0.\\n\\n■ Cloud Firestore\\nCopyright 2020 Google LLC. All rights reserved.\\nLicensed under the Apache License, Version 2.0.\\n\\n■ Supabase Flutter\\nCopyright (c) 2021 Supabase. All rights reserved.\\nLicensed under the MIT License.\\n\\n■ Connectivity Plus\\nCopyright 2020 The Chromium Authors. All rights reserved.\\nLicensed under the BSD-style License.\\n\\n■ Cupertino Icons\\nCopyright 2020 The Flutter Authors. All rights reserved.\\nLicensed under the MIT License.'**
  String get open_source_licenses_content;

  /// No description provided for @faq_q1.
  ///
  /// In en, this message translates to:
  /// **'How do I swap skills?'**
  String get faq_q1;

  /// No description provided for @faq_a1.
  ///
  /// In en, this message translates to:
  /// **'Browse through the listings on the Home Screen. If you see a skill you want to learn, tap on it and select '**
  String get faq_a1;

  /// No description provided for @faq_q2.
  ///
  /// In en, this message translates to:
  /// **'Is Skill Swap completely free?'**
  String get faq_q2;

  /// No description provided for @faq_a2.
  ///
  /// In en, this message translates to:
  /// **'Yes, absolutely! Skill Swap is built on a direct barter peer-to-peer learning model. You share your expertise in exchange for learning something new. No financial transactions are involved.'**
  String get faq_a2;

  /// No description provided for @faq_q3.
  ///
  /// In en, this message translates to:
  /// **'How do I change my offered skills?'**
  String get faq_q3;

  /// No description provided for @faq_a3.
  ///
  /// In en, this message translates to:
  /// **'To update or delete an offered skill, go to the Home Screen and tap See All. Open the skill listing you want to manage to view its details, then tap the three-dot menu in the top-right corner. From there, select Edit Skill to make changes or Delete Skill to remove the listing.'**
  String get faq_a3;

  /// No description provided for @faq_q4.
  ///
  /// In en, this message translates to:
  /// **'What should I do if a user is offensive or inactive?'**
  String get faq_q4;

  /// No description provided for @faq_a4.
  ///
  /// In en, this message translates to:
  /// **'You can open the user\'s profile or chat, click the options menu (three dots), and select '**
  String get faq_a4;

  /// No description provided for @faq_q5.
  ///
  /// In en, this message translates to:
  /// **'Can I offer multiple skills at the same time?'**
  String get faq_q5;

  /// No description provided for @faq_a5.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can list as many skills as you want. Simply tap the '**
  String get faq_a5;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'hi', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
