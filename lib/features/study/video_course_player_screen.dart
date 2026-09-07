import 'package:flutter/material.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/language_service.dart';
import '../../core/widgets/youtube_embed_widget.dart';

class VideoCoursePlayerScreen extends StatefulWidget {
  final VideoCourse course;
  final int initialLessonIndex;

  const VideoCoursePlayerScreen({
    super.key,
    required this.course,
    this.initialLessonIndex = 0,
  });

  @override
  State<VideoCoursePlayerScreen> createState() => _VideoCoursePlayerScreenState();
}

class _VideoCoursePlayerScreenState extends State<VideoCoursePlayerScreen> {
  late int _currentLessonIndex;
  late List<CourseLesson> _lessons;

  @override
  void initState() {
    super.initState();
    _lessons = widget.course.effectiveLessons;
    _currentLessonIndex = widget.initialLessonIndex.clamp(0, _lessons.isEmpty ? 0 : _lessons.length - 1);
  }

  CourseLesson? get _currentLesson =>
      _lessons.isNotEmpty ? _lessons[_currentLessonIndex] : null;

  void _selectLesson(int index) {
    if (index >= 0 && index < _lessons.length) {
      setState(() {
        _currentLessonIndex = index;
      });
    }
  }

  void _nextLesson() {
    if (_currentLessonIndex < _lessons.length - 1) {
      _selectLesson(_currentLessonIndex + 1);
    }
  }

  void _prevLesson() {
    if (_currentLessonIndex > 0) {
      _selectLesson(_currentLessonIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _currentLesson;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            if (lesson != null)
              Text(
                '${LanguageService.instance.trText(ne: 'पाठ', en: 'Lesson', ko: '강의')} ${_currentLessonIndex + 1}/${_lessons.length}: ${lesson.title}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade900.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.teal.shade400, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 12, color: Colors.tealAccent),
                const SizedBox(width: 4),
                Text(
                  LanguageService.instance.trText(
                    ne: '🔒 पाठ्यक्रम मोड',
                    en: '🔒 Course Mode',
                    ko: '🔒 정규 과정 모드',
                  ),
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isWide ? _buildWideLayout(lesson) : _buildMobileLayout(lesson),
    );
  }

  // Wide Desktop/Tablet Layout (Side-by-side Video + Playlist)
  Widget _buildWideLayout(CourseLesson? lesson) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Main Video Player Area
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoPlayerBox(lesson),
                const SizedBox(height: 16),
                _buildCourseNavControls(),
                const SizedBox(height: 16),
                _buildLessonDetailsCard(lesson),
              ],
            ),
          ),
        ),

        // Right Syllabus / Lesson Playlist Sidebar
        Container(
          width: 380,
          color: const Color(0xFF1E293B),
          child: _buildPlaylistSidebar(),
        ),
      ],
    );
  }

  // Mobile / Narrow Layout (Stacked)
  Widget _buildMobileLayout(CourseLesson? lesson) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticky Video Player Box
          _buildVideoPlayerBox(lesson),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseNavControls(),
                const SizedBox(height: 12),
                _buildLessonDetailsCard(lesson),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Text(
                  '📑 ${LanguageService.instance.trText(ne: 'पाठ्यक्रम सूची (कुल ${_lessons.length} पाठ)', en: 'Course Syllabus (${_lessons.length} Lessons)', ko: '강의 목록 (${_lessons.length}강)')}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildPlaylistList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. YouTube Distraction-Free Embedded Player Container
  Widget _buildVideoPlayerBox(CourseLesson? lesson) {
    final videoId = lesson?.youtubeId ?? widget.course.youtubeId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YouTubeEmbedPlayer(
          key: ValueKey('player-$videoId-$_currentLessonIndex'),
          videoId: videoId,
          autoPlay: true,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }

  // 2. Focused Navigation Controls (Prev, Lesson X/Y, Next)
  Widget _buildCourseNavControls() {
    final hasPrev = _currentLessonIndex > 0;
    final hasNext = _currentLessonIndex < _lessons.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPrev ? const Color(0xFF334155) : Colors.transparent,
              foregroundColor: hasPrev ? Colors.white : Colors.white30,
              elevation: hasPrev ? 1 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: hasPrev ? _prevLesson : null,
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            label: Text(
              LanguageService.instance.trText(ne: 'अघिल्लो पाठ', en: 'Prev Lesson', ko: '이전 강의'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${LanguageService.instance.trText(ne: 'पाठ', en: 'Lesson', ko: '강')} ${_currentLessonIndex + 1} / ${_lessons.length}',
              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasNext ? const Color(0xFF1E3A8A) : Colors.transparent,
              foregroundColor: hasNext ? Colors.white : Colors.white30,
              elevation: hasNext ? 1 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: hasNext ? _nextLesson : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            label: Text(
              LanguageService.instance.trText(ne: 'अर्को पाठ', en: 'Next Lesson', ko: '다음 강의'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Lesson Details & Notes Card
  Widget _buildLessonDetailsCard(CourseLesson? lesson) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.course.category,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              if (lesson?.duration.isNotEmpty ?? false)
                Text(
                  '⏱️ ${lesson!.duration}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              const Spacer(),
              Text(
                '👨‍🏫 ${widget.course.instructor}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lesson?.title ?? widget.course.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            (lesson?.summary?.isNotEmpty ?? false) ? lesson!.summary! : widget.course.description,
            style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          // Distraction-free guarantee notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade800, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.tealAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LanguageService.instance.trText(
                      ne: '🎯 ध्यान नभड्किने सिकाइ: युट्युबका अनावश्यक सिफारिसहरू रोकिएका छन्। विद्यार्थीले पाठ्यक्रमको मात्र भिडियो हेरेर अध्ययन गर्न सक्नेछन्।',
                      en: '🎯 Distraction-Free Learning: Unrelated YouTube recommendations are blocked. Students focus strictly on course syllabus.',
                      ko: '🎯 집중 학습 모드: 외부 유튜브 추천 동영상이 차단되어 강의 내용에만 집중할 수 있습니다.',
                    ),
                    style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Playlist Sidebar for Wide Screen
  Widget _buildPlaylistSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: const Color(0xFF0F172A),
          child: Row(
            children: [
              const Icon(Icons.playlist_play, color: Colors.amberAccent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageService.instance.trText(
                    ne: 'पाठ्यक्रम तालिका (${_lessons.length} पाठ)',
                    en: 'Course Syllabus (${_lessons.length} Lessons)',
                    ko: '강의 커리큘럼 (${_lessons.length}강)',
                  ),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF334155)),
        Expanded(
          child: _buildPlaylistList(),
        ),
      ],
    );
  }

  // 5. Playlist List
  Widget _buildPlaylistList() {
    return ListView.separated(
      itemCount: _lessons.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF334155)),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, idx) {
        final item = _lessons[idx];
        final isActive = idx == _currentLessonIndex;

        return ListTile(
          dense: true,
          tileColor: isActive ? const Color(0xFF1E3A8A).withOpacity(0.5) : Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? Colors.amberAccent : const Color(0xFF334155),
              shape: BoxShape.circle,
            ),
            child: isActive
                ? const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18)
                : Text(
                    '${idx + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: item.duration.isNotEmpty
              ? Text('⏱️ ${item.duration}', style: const TextStyle(color: Colors.white38, fontSize: 11))
              : null,
          trailing: isActive
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('PLAYING', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                )
              : const Icon(Icons.play_circle_outline, size: 16, color: Colors.white24),
          onTap: () => _selectLesson(idx),
        );
      },
    );
  }
}
