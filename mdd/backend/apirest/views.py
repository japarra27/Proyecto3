from django.shortcuts import render
from django.http import Http404
from apirest.models import *
from rest_framework.views import APIView
from rest_framework import status, generics
from django.contrib.auth.models import User
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.views.decorators.cache import cache_page
from django.core.cache.backends.base import DEFAULT_TIMEOUT
from apirest.serializers import *
from django.core.mail import send_mail
from django.conf import settings

CACHE_TTL = getattr(settings, 'CACHE_TTL', DEFAULT_TIMEOUT)

# Create your views here.
class UserCreateAPIView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = (AllowAny,)

class Projects(APIView):
    def get(self, request):
        project = Project.objects.all()
        serializer = ProjectSerializer(project, many = True)
        return Response(serializer.data)

    def post(self, request):
        serializer = ProjectSerializer(data = request.data)
        if serializer.is_valid():
            serializer.save(project_company = request.user)
            return Response(serializer.data, status = status.HTTP_201_CREATED)
        return Response(serializer.errors, status = status.HTTP_400_BAD_REQUEST)

@cache_page(CACHE_TTL)
class ProjectDetail(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request, project_id):
        try:
            project = Project.objects.get(pk = project_id)
        except Project.DoesNotExist:
            raise Http404
        serializer = ProjectSerializer(project)
        return Response(serializer.data)

    def put(self, request, project_id):
        try:
            project = Project.objects.get(project_company = request.user, pk = project_id)
        except Project.DoesNotExist:
            raise Http404

        serializer = ProjectSerializer(project, data = request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status = status.HTTP_202_ACCEPTED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, project_id):
        try:
            project = Project.objects.get(project_company = request.user, pk = project_id)
        except Project.DoesNotExist:
            raise Http404
        project.delete()
        return Response(status = status.HTTP_204_NO_CONTENT)

@cache_page(CACHE_TTL)
class Designs(APIView):
    permission_classes = (AllowAny,)

    def get(self, request, project_id):
        design = Design.objects.filter(design_project_id = project_id ) 
        serializer = DesignSerializer(design, many = True)
        return Response(serializer.data)

    def post(self, request, project_id):
        serializer = DesignSerializer(data = request.data)
        if serializer.is_valid():
            ser = serializer.save(design_project_id = project_id)
            ser.save()
            return Response(serializer.data, status = status.HTTP_201_CREATED)
        return Response(serializer.errors, status = status.HTTP_400_BAD_REQUEST)

@cache_page(CACHE_TTL)
class DesignDetail(APIView):
    def get(self, request, project_id, design_id):
        try:
            design = Design.objects.get(project_id = project_id, pk = design_id)
        except Design.DoesNotExist:
            raise Http404
        serializer = DesignSerializer(design)
        return Response(serializer.data)
