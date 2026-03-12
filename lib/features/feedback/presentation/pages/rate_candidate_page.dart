import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/submit_candidate_rating_request.dart';
import '../../data/repositories/feedback_repository.dart';

class RateCandidatePage extends StatefulWidget {
  final int sessionId;
  final int jobSeekerId;
  final String jobSeekerName;

  const RateCandidatePage({
    super.key,
    required this.sessionId,
    required this.jobSeekerId,
    required this.jobSeekerName,
  });

  @override
  State<RateCandidatePage> createState() => _RateCandidatePageState();
}

class _RateCandidatePageState extends State<RateCandidatePage> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  late final FeedbackRepository _repository;

  // 5 rating dimensions (1-5 stars each)
  int _professionalismRating = 0;
  int _communicationRating = 0;
  int _preparednessRating = 0;
  int _engagementRating = 0;
  int _commitmentRating = 0;
  bool _wouldRecommend = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = FeedbackRepository(dioClient);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validate all ratings are provided
    if (_professionalismRating == 0 ||
        _communicationRating == 0 ||
        _preparednessRating == 0 ||
        _engagementRating == 0 ||
        _commitmentRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate all dimensions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create candidate rating request
      final request = SubmitCandidateRatingRequest(
        candidateId: widget.jobSeekerId,
        mentorshipSessionId: widget.sessionId,
        professionalism: _professionalismRating,
        communication: _communicationRating,
        preparedness: _preparednessRating,
        engagement: _engagementRating,
        commitment: _commitmentRating,
        review: _reviewController.text.isEmpty ? null : _reviewController.text,
        wouldRecommend: _wouldRecommend,
      );

      // Submit rating
      await _repository.submitCandidateRating(request);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Candidate'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Candidate Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                    Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Text(
                                  widget.jobSeekerName[0].toUpperCase(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.jobSeekerName,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rate this candidate based on the mentorship session',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rating Dimensions
                      _buildRatingDimension(
                        'Professionalism',
                        'Professional attitude and conduct',
                        _professionalismRating,
                        (rating) => setState(() => _professionalismRating = rating),
                      ),
                      const SizedBox(height: 20),

                      _buildRatingDimension(
                        'Communication',
                        'Clarity and effectiveness in communication',
                        _communicationRating,
                        (rating) => setState(() => _communicationRating = rating),
                      ),
                      const SizedBox(height: 20),

                      _buildRatingDimension(
                        'Preparedness',
                        'Level of preparation for the session',
                        _preparednessRating,
                        (rating) => setState(() => _preparednessRating = rating),
                      ),
                      const SizedBox(height: 20),

                      _buildRatingDimension(
                        'Engagement',
                        'Active participation and interest',
                        _engagementRating,
                        (rating) => setState(() => _engagementRating = rating),
                      ),
                      const SizedBox(height: 20),

                      _buildRatingDimension(
                        'Commitment',
                        'Dedication and follow-through',
                        _commitmentRating,
                        (rating) => setState(() => _commitmentRating = rating),
                      ),
                      const SizedBox(height: 24),

                      // Review Text
                      CustomTextField(
                        label: 'Additional Comments (Optional)',
                        hint: 'Share your detailed feedback about the candidate...',
                        controller: _reviewController,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),

                      // Would Recommend Checkbox
                      Card(
                        color: _wouldRecommend ? Colors.green[50] : Colors.grey[100],
                        child: CheckboxListTile(
                          title: const Text('I would recommend this candidate to employers'),
                          subtitle: const Text(
                            'This rating is internal and helps improve our matching system',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _wouldRecommend,
                          onChanged: (value) {
                            setState(() {
                              _wouldRecommend = value ?? true;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomButton(
                  text: 'Submit Rating',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  icon: Icons.send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingDimension(
    String title,
    String subtitle,
    int currentRating,
    Function(int) onRatingChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () => onRatingChanged(index + 1),
              icon: Icon(
                index < currentRating ? Icons.star : Icons.star_border,
                size: 36,
                color: Colors.amber,
              ),
            );
          }),
        ),
      ],
    );
  }
}
