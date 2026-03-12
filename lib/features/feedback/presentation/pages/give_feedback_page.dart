import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/submit_feedback_request.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../domain/entities/feedback_entity.dart';

class GiveFeedbackPage extends StatefulWidget {
  final String sessionId;
  final String jobSeekerId;
  final String jobSeekerName;

  const GiveFeedbackPage({
    super.key,
    required this.sessionId,
    required this.jobSeekerId,
    required this.jobSeekerName,
  });

  @override
  State<GiveFeedbackPage> createState() => _GiveFeedbackPageState();
}

class _GiveFeedbackPageState extends State<GiveFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _strengthController = TextEditingController();
  final _improvementController = TextEditingController();
  late final FeedbackRepository _repository;

  FeedbackType _selectedType = FeedbackType.overall;
  int _rating = 0;
  final List<String> _strengths = [];
  final List<String> _improvements = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final dioClient = DioClient(const FlutterSecureStorage());
    _repository = FeedbackRepository(dioClient);
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _strengthController.dispose();
    _improvementController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate() && _rating > 0) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Convert feedback type to string
        final typeString = _selectedType.toString().split('.').last;

        // Create feedback request
        final request = SubmitFeedbackRequest(
          sessionId: widget.sessionId,
          jobSeekerId: widget.jobSeekerId,
          type: typeString,
          rating: _rating,
          comments: _commentsController.text,
          strengths: _strengths,
          areasForImprovement: _improvements,
        );

        // Submit feedback
        await _repository.submitFeedback(request);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        context.pop(true); // Return true to indicate success
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _addStrength() {
    if (_strengthController.text.isNotEmpty) {
      setState(() {
        _strengths.add(_strengthController.text);
        _strengthController.clear();
      });
    }
  }

  void _addImprovement() {
    if (_improvementController.text.isNotEmpty) {
      setState(() {
        _improvements.add(_improvementController.text);
        _improvementController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Feedback'),
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
                      // Candidate Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
                                      'Provide feedback to help them improve',
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

                      // Feedback Type
                      Text(
                        'Feedback Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<FeedbackType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: FeedbackType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_formatFeedbackType(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Rating
                      Text(
                        'Rating',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              size: 40,
                              color: Colors.amber,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Comments
                      CustomTextField(
                        label: 'Comments',
                        hint: 'Provide detailed feedback...',
                        controller: _commentsController,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide comments';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Strengths
                      Text(
                        'Strengths',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _strengthController,
                              decoration: InputDecoration(
                                hintText: 'Add a strength',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onSubmitted: (_) => _addStrength(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _addStrength,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      if (_strengths.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _strengths.asMap().entries.map((entry) {
                            return Chip(
                              label: Text(entry.value),
                              backgroundColor: Colors.green[50],
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _strengths.removeAt(entry.key);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Areas for Improvement
                      Text(
                        'Areas for Improvement',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _improvementController,
                              decoration: InputDecoration(
                                hintText: 'Add an improvement area',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onSubmitted: (_) => _addImprovement(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _addImprovement,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      if (_improvements.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _improvements.asMap().entries.map((entry) {
                            return Chip(
                              label: Text(entry.value),
                              backgroundColor: Colors.orange[50],
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _improvements.removeAt(entry.key);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
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
                  text: 'Submit Feedback',
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

  String _formatFeedbackType(FeedbackType type) {
    switch (type) {
      case FeedbackType.interviewPerformance:
        return 'Interview Performance';
      case FeedbackType.technicalSkills:
        return 'Technical Skills';
      case FeedbackType.communicationSkills:
        return 'Communication Skills';
      case FeedbackType.overall:
        return 'Overall Assessment';
    }
  }
}
